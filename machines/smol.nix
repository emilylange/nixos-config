# printf "label: gpt\n,512M,uefi\n,,linux" | sfdisk /dev/vda
# mkfs.fat -n EFIBOOT /dev/vda1
# mkfs.ext4 -L EXT4 /dev/vda2
#
# mount /dev/vda2 /mnt/
# mkdir /mnt/boot
# mount /dev/vda1 /mnt/boot/
#
# HOST: nix build .#nixosConfigurations.smol.config.system.build.toplevel --print-out-paths
# HOST: nix copy -s --to "ssh://smol?remote-store=local?root=/mnt&compress=1" .#nixosConfigurations.smol.config.system.build.toplevel
# nix-env --store /mnt --profile /mnt/nix/var/nix/profiles/system --set <outPath>
# mkdir /mnt/etc
# touch /mnt/etc/NIXOS
# NIXOS_INSTALL_BOOTLOADER=1 nixos-enter -- /run/current-system/bin/switch-to-configuration boot

{ modulesPath, ... }:

{
  imports = [
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  networking = {
    useDHCP = false;
    usePredictableInterfaceNames = false;
  };

  systemd.network = {
    enable = true;

    networks = {
      "10-ethernet-uplink" = {
        matchConfig.Name = [ "eth0" ];
        linkConfig.RequiredForOnline = "routable";

        address = [
          "5.252.227.124/22"
          "2a03:4000:40:94::1/64"
        ];

        routes = [
          { Gateway = "5.252.224.1"; }
          { Gateway = "fe80::1"; }
        ];
      };
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    growPartition = true;
    kernelParams = [ "console=ttyS0" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/EXT4";
      fsType = "ext4";
      options = [
        "noatime"
      ];
    };

    "/boot" = {
      device = "/dev/disk/by-label/EFIBOOT";
      fsType = "vfat";
      options = [
        "umask=0077"
      ];
    };
  };

  services.qemuGuest.enable = true;

  system.stateVersion = "23.11";
}
