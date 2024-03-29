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

{ config, nodes, self, pkgs, ... }:

{
  imports = [
    ../presets/server/home-assistant
    ../presets/server/paperless
  ];

  networking.interfaces.eth0.ipv4.addresses = [{
    address = "192.168.10.12";
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

  networking.firewall = {
    allowedTCPPorts = [
      8123 ## homeassistant
    ];
    interfaces.eth0.allowedTCPPorts = [
      1883 ## mqtt
    ];
  };

  networking.wireguard.interfaces = {
    hass = {
      ips = [ "192.168.11.10/32" ];
      privateKeyFile = config.deployment.keys."wg-hass".path;
      peers = [
        {
          ## TODO: allowedIps has to end with `.0/24`, so maybe add some cird parsing
          allowedIPs = [ "192.168.11.0/24" ];
          endpoint = "netcup01.gkcl.de:${toString nodes.netcup01.config.networking.wireguard.interfaces.hass.listenPort}";
          publicKey = config.redacted.netcup01.wireguard.hass.publicKey;
          persistentKeepalive = 25;
        }
      ];
    };
  };

  deployment.keys."wg-hass" = {
    destDir = "/";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/futro/wireguard/hass/privateKey" ];
  };

  services.gitea-actions-runner = {
    package = pkgs.forgejo-actions-runner;
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
      ];
    };
  };
  # TODO: fix this upstream
  systemd.services.gitea-runner-native.environment.HOME = "/var/lib/gitea-runner/native";

  system.stateVersion = "22.05";
}
