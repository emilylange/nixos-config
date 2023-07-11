## base: https://github.com/nix-community/infra/blob/da770be0bc0c5a6a7a2df4d6a9be5d3e6516ed05/build04/configuration.nix
## commands within kexec:
##  printf "label: gpt\n,550M,U\n,,L\n" | sfdisk /dev/sda
##  mkfs.fat -n EFIBOOT -F 32 /dev/sda1
##  mkfs.btrfs -L btrfs /dev/sda2
##  mkdir -p /mnt
##  mount /dev/sda2 /mnt
##  btrfs subvolume create /mnt/@
##  btrfs subvolume create /mnt/@nix
##  umount /mnt
##  mount -o compress-force=zstd,noatime,subvol=@ /dev/sda2 /mnt
##  mkdir /mnt/{nix,boot}
##  mount -o compress-force=zstd,noatime,subvol=@nix /dev/sda2 /mnt/nix
##  mount /dev/sda1 /mnt/boot
##  nixos-generate-config --root /mnt
##  nixos-install --no-root-passwd

{ modulesPath, config, nodes, self, ... }:

{
  imports = [
    ../presets/server/matrix-synapse
    ../presets/server/nextcloud
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  ## Oracle Cloud's current IPv6 support is pretty annoying to setup, ngl.
  ## It also heavily relies on dhcp, as the gateway IP seems to be dynamic.
  ## So we configure a specific "provisioned" IPv6 address,
  ## but use dhcp for the gateway anyway.
  ## This allows use to reference and use this IP in other places within this flake.
  networking.interfaces.eth0.ipv6.addresses = [{
    address = "2603:c020:800b:36ff::abcd";
    prefixLength = 64;
  }];

  fileSystems = {
    "/" = {
      device = "/dev/sda2";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "noatime"
        "compress-force=zstd"
      ];
    };

    "/nix" = {
      device = "/dev/sda2";
      fsType = "btrfs";
      options = [
        "subvol=@nix"
        "noatime"
        "compress-force=zstd"
      ];
    };

    "/boot" = {
      device = "/dev/sda1";
      fsType = "vfat";
    };
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = false;
  };

  networking.wireguard.interfaces.internal = {
    ips = [ "192.168.90.44/32" ];
    listenPort = 51342;
    privateKeyFile = config.deployment.keys."wg-internal".path;
    peers = [
      {
        allowedIPs = nodes.futro.config.networking.wireguard.interfaces.internal.ips;
        publicKey = config.redacted.futro.wireguard.internal.publicKey;
      }
      {
        allowedIPs = nodes.netcup01.config.networking.wireguard.interfaces.internal.ips;
        publicKey = config.redacted.netcup01.wireguard.internal.publicKey;
        endpoint = with nodes.netcup01.config.networking; "[${self.headAddress interfaces.eth0.ipv6}]:${toString wireguard.interfaces.internal.listenPort}";
      }
    ];
  };

  deployment.keys."wg-internal" = {
    destDir = "/";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/altra/wireguard/internal/privateKey" ];
  };

  networking.firewall.allowedUDPPorts = [
    config.networking.wireguard.interfaces.internal.listenPort
  ];

  services.qemuGuest.enable = true;

  nixpkgs.system = "aarch64-linux";
  system.stateVersion = "22.05";
}
