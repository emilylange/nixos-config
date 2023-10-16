# The following `sfdisk` commands leaves 512MiB unassigned space between the uefi and the raid partition.
# We do this, because we run in raid(1) and any replacement disk might have a slightly size.
# In case the replacement is disk is slightly smaller than the one it replaces,
# we have some headroom to accommodate for the difference in size, by using some of the 512MiB's unassigned space.
#
# printf "label: gpt\n,512M,uefi\n1024M,,raid" | sfdisk /dev/nvme0n1
# printf "label: gpt\n,512M,uefi\n1024M,,raid" | sfdisk /dev/nvme1n1
#
# We format both uefi partitions, but will only use one, for the time being, until we support proper systemd-boot raid(1) in NixOS.
# mkfs.fat -n EFIBOOT1 /dev/nvme0n1p1
# mkfs.fat -n EFIBOOT2 /dev/nvme1n1p1
#
# mdadm --create --verbose --level=1 --raid-devices=2 --homehost=any /dev/md0 /dev/nvme0n1p2 /dev/nvme1n1p2
# cryptsetup luksFormat /dev/md0
# cryptsetup open /dev/md0 raid
# pvcreate /dev/mapper/raid
# vgcreate lvmraid /dev/mapper/raid
# lvcreate --size 256G --name ext4 lvmraid
# lvcreate --extents 100%FREE --name btrfs lvmraid
# lvreduce --size -256M /dev/lvmraid/btrfs
# mkfs.ext4 -L ext4 /dev/lvmraid/ext4
# mkfs.btrfs -L btrfs /dev/lvmraid/btrfs
#
# mount /dev/disk/by-label/btrfs /mnt
# btrfs subvolume create /mnt/@
# btrfs subvolume create /mnt/@nix
# umount /mnt
#
# mount -o compress-force=zstd,subvol=@ /dev/disk/by-label/btrfs /mnt
# mkdir /mnt/{boot,ext4,nix}
# mount -o compress-force=zstd,subvol=@nix /dev/disk/by-label/btrfs /mnt/nix
# mount /dev/disk/by-label/EFIBOOT1 /mnt/boot
# mount /dev/disk/by-label/ext4 /mnt/ext4
# nixos-generate-config --root /mnt
# mkdir -p /mnt/etc/secrets/initrd/
# ssh-keygen -t ed25519 -N "" -f /mnt/etc/secrets/initrd/ssh_host_ed25519_key
#
# HOST: nix build .#nixosConfigurations.wip.config.system.build.toplevel --print-out-paths
# HOST: nix copy -s --to "ssh://wip?remote-store=local?root=/mnt&compress=1" .#nixosConfigurations.wip.config.system.build.toplevel
# nix-env --store /mnt --profile /mnt/nix/var/nix/profiles/system --set <outPath>
# touch /mnt/etc/NIXOS
# NIXOS_INSTALL_BOOTLOADER=1 nixos-enter -- /run/current-system/bin/switch-to-configuration boot

{ pkgs, config, ... }:

{
  networking.usePredictableInterfaceNames = true;
  systemd.network = {
    enable = true;
    networks = {
      "10-ethernet-uplink" = {
        matchConfig.Name = [ "en*" "eth*" ];
        linkConfig.RequiredForOnline = "routable";
        address = [
          "2a01:4f8:190:441a::/64"
        ];
        routes = [
          { routeConfig.Gateway = "fe80::1"; }
        ];
      };

      ## AnyIP in systemd-networkd :)
      ## same as `ip -6 route add local 2a01:4f8:190:441a::/64 dev lo`
      "20-anyip" = {
        matchConfig.Name = [ "lo" ];
        routes = [{
          routeConfig = {
            Type = "local";
            Destination = "2a01:4f8:190:441a::/64";
          };
        }];
      };
    };
  };

  boot.swraid.enable = true;
  boot.initrd.luks.devices."raid" = {
    device = "/dev/md0";
    allowDiscards = true;
    preLVM = true;
  };
  services.lvm.enable = true;
  fileSystems = {
    "/" = {
      label = "btrfs";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "compress-force=zstd"
      ];
    };

    "/nix" = {
      label = "btrfs";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "compress-force=zstd"
      ];
    };

    "/boot" = {
      label = "EFIBOOT1";
      fsType = "vfat";
    };

    "/ext4" = {
      label = "ext4";
      fsType = "ext4";
    };
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.emergencyAccess = true;
  boot.initrd.systemd.network.enable = true;
  boot.initrd.systemd.network.networks = config.systemd.network.networks;
  boot.initrd.systemd.initrdBin = [ pkgs.iproute2 ];

  boot.initrd.network.ssh = {
    enable = true;
    hostKeys = [
      "/etc/secrets/initrd/ssh_host_ed25519_key"
    ];
  };

  boot.kernelModules = [ "kvm-amd" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"

    ## ethernet
    "e1000"
    "e1000e"
    "r8169"
    "virtio-net"
  ];

  hardware.cpu.amd.updateMicrocode = true;

  system.stateVersion = "23.11";
}