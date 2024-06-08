## commands within kexec:
##  systemctl stop autoreboot.timer
##  printf "label: gpt\n,550M,U\n,,L\n" | sfdisk /dev/sda
##  mkfs.fat -n EFIBOOT -F 32 /dev/sda1
##  cryptsetup luksFormat --label BTRFSCRYPT /dev/sda2
##  cryptsetup open /dev/disk/by-label/BTRFSCRYPT btrfs
##  mkfs.btrfs -L BTRFS /dev/mapper/btrfs
##  mount -t btrfs /dev/disk/by-label/BTRFS /mnt
##  btrfs subvolume create /mnt/@
##  btrfs subvolume create /mnt/@nix
##  umount /mnt
##  mount -o compress-force=zstd,noatime,subvol=@ /dev/disk/by-label/BTRFS /mnt
##  mkdir /mnt/{nix,boot}
##  mount -o compress-force=zstd,noatime,subvol=@nix /dev/disk/by-label/BTRFS /mnt/nix
##  mount /dev/disk/by-label/EFIBOOT /mnt/boot
##  nixos-generate-config --root /mnt
##  mkdir -p /mnt/etc/secrets/initrd/
##  ssh-keygen -t ed25519 -N "" -f /mnt/etc/secrets/initrd/ssh_host_ed25519_key
##  ./colmena-bootstrap futro /mnt # https://gist.github.com/zhaofengli/e986fa7688d6c16872b86c6ae6215c9b

{ config, self, ... }:

{
  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.10.13";
    prefixLength = 24;
  }];

  networking.defaultGateway = {
    address = "192.168.10.1";
    interface = "eth0";
  };

  ## use DHCP for IPv6
  networking.interfaces.eth0.useDHCP = true;

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/BTRFS";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "noatime"
        "compress-force=zstd"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-label/BTRFS";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "noatime"
        "compress-force=zstd"
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

  boot = {
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      (
        let
          client-ip = self.headAddress config.networking.interfaces.${device}.ipv4;
          gw-ip = config.networking.defaultGateway.address;
          netmask = "255.255.255.0"; ## TODO: https://github.com/NixOS/nixpkgs/issues/36299
          device = "eth0";
        in
        "ip=${client-ip}::${gw-ip}:${netmask}:${config.networking.hostName}:${device}:"
      )
    ];

    initrd = {
      availableKernelModules = [
        "ahci"
        "xhci_pci"
        "usb_storage"
        "uas"
        "sd_mod"
        "r8169" ## ethernet
      ];

      luks.devices."btrfs" = {
        device = "/dev/disk/by-label/BTRFSCRYPT";
        allowDiscards = true;
      };

      network = {
        enable = true;
        ssh = {
          enable = true;
          hostKeys = [
            "/etc/secrets/initrd/ssh_host_ed25519_key"
          ];
        };
      };
    };

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  hardware.cpu.intel.updateMicrocode = true;
  services.fstrim.enable = true;
  services.fwupd.enable = true;

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "ondemand";
    ## TODO: eval `services.tlp`
    powertop.enable = true;
  };

  system.stateVersion = "22.05";
}
