# printf "label: gpt\n,512M,U\n,,L\n" | sfdisk /dev/nvme0n1
# mkfs.fat -n EFIBOOT -F 32 /dev/nvme0n1p1
# cryptsetup luksFormat --label BTRFSCRYPT /dev/nvme0n1p2
# cryptsetup open /dev/disk/by-label/BTRFSCRYPT btrfs
# mkfs.btrfs -L BTRFS /dev/mapper/btrfs
# mount -t btrfs /dev/disk/by-label/btrfs /mnt
# btrfs subvolume create /mnt/@
# btrfs subvolume create /mnt/@nix
# umount /mnt
# mount -o compress-force=zstd,noatime,subvol=@ /dev/disk/by-label/btrfs /mnt
# mkdir /mnt/{nix,boot}
# mount -o compress-force=zstd,noatime,subvol=@nix /dev/disk/by-label/btrfs /mnt/nix
# mount /dev/nvme0n1p1 /mnt/boot
# nixos-generate-config --root /mnt
# mkdir -p /mnt/etc/secrets/initrd/
# ssh-keygen -t ed25519 -N "" -C "" -f /mnt/etc/secrets/initrd/ssh_host_ed25519_key
#
# HOST: nix build .#nixosConfigurations.spof.config.system.build.toplevel --print-out-paths
# HOST: nix copy --to "ssh://spof?remote-store=local?root=/mnt" .#nixosConfigurations.spof.config.system.build.toplevel
# nix-env --store /mnt --profile /mnt/nix/var/nix/profiles/system --set <outPath>
# touch /mnt/etc/NIXOS
# NIXOS_INSTALL_BOOTLOADER=1 nixos-enter -- /run/current-system/bin/switch-to-configuration boot

{ modulesPath, pkgs, config, inputs, ... }:

{
  imports = [
    ../presets/server/home-assistant
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  services.gitea-actions-runner = {
    package = pkgs.forgejo-runner;
    instances."native" = {
      enable = true;
      name = "native";
      url = "https://git.geklaute.cloud";
      labels = [
        "native:host"
      ];
      tokenFile = "/forgejo_runner_token_native";
      hostPackages = with pkgs; [
        bash
        coreutils
        gitMinimal
        nix
        nodejs
        openssh
      ];
    };
  };

  networking.useDHCP = false;
  systemd.network = {
    enable = true;
    networks = {
      "10-ethernet-uplink" = {
        matchConfig.Name = [ "eno1" ];
        address = [ "192.168.10.2/24" "192.168.10.12/24" ];
        routes = [{ Gateway = "192.168.10.1"; }];
      };
    };
  };

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
      label = "EFIBOOT";
      fsType = "vfat";
      options = [
        "umask=0077"
      ];
    };
  };

  boot = {
    initrd.luks.devices."btrfs" = {
      device = "/dev/disk/by-label/BTRFSCRYPT";
      allowDiscards = true;
    };

    loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };

    initrd = {
      systemd = {
        enable = true;
        emergencyAccess = true;
        network.enable = true;
        network.networks = { inherit (config.systemd.network.networks) "10-ethernet-uplink"; };
        initrdBin = [ pkgs.iproute2 ];
      };

      network.ssh = {
        enable = true;
        port = 2222;
        hostKeys = [
          "/etc/secrets/initrd/ssh_host_ed25519_key"
        ];
      };
    };

    kernelModules = [ "kvm-intel" ];
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "e1000e"
    ];
  };

  hardware.cpu.intel.updateMicrocode = true;

  system.stateVersion = "24.05";
}
