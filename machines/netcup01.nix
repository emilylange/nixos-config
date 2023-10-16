{ config, pkgs, modulesPath, nodes, self, ... }:

{
  imports = [
    ../presets/common/docker
    ../presets/server/acme-dns
    ../presets/server/caddy
    ../presets/server/coturn
    ../presets/server/drone
    ../presets/server/drone/server
    ../presets/server/forgejo
    ../presets/server/miniflux
    ../presets/server/ntfy-sh
    ../presets/server/uptime-kuma
    ../presets/server/vaultwarden
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  systemd.network = {
    enable = true;
    networks = {
      "10-ethernet-uplink" = {
        matchConfig.Name = [ "en*" "eth*" ];
        linkConfig.RequiredForOnline = "routable";
        address = [
          "2.56.98.73/22"
          "2a03:4000:3e:1f8::1/64"
        ];
        routes = [
          { routeConfig.Gateway = "2.56.96.1"; }
          { routeConfig.Gateway = "fe80::1"; }
        ];
      };
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/efi";
    };
    growPartition = true;
    kernelParams = [ "console=ttyS0" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos";
      fsType = "btrfs";
      options = [
        "subvol=@"
        "noatime"
        "compress-force=zstd"
      ];
    };

    "/efi" = {
      device = "/dev/disk/by-label/EFIBOOT";
      fsType = "vfat";
    };
  };

  ## gitea's internal ssh server runs on :22
  services.openssh.ports = [ 22222 ];

  zramSwap = {
    enable = true;
    memoryPercent = 10;
  };
  services.qemuGuest.enable = true;

  networking.firewall.allowedUDPPorts = [
    config.networking.wireguard.interfaces.hass.listenPort
    config.networking.wireguard.interfaces.internal.listenPort
  ];

  networking.wireguard.interfaces = {
    internal = {
      ips = [ "192.168.90.55/32" ];
      listenPort = 23764;
      privateKeyFile = config.deployment.keys."wg-internal".path;
      peers = [
        {
          allowedIPs = nodes.altra.config.networking.wireguard.interfaces.internal.ips;
          endpoint = with nodes.altra.config.networking; "[${self.headAddress interfaces.eth0.ipv6}]:${toString wireguard.interfaces.internal.listenPort}";
          publicKey = config.redacted.altra.wireguard.internal.publicKey;
        }
      ];
    };

    hass = {
      ips = [ "192.168.11.20/24" ];
      listenPort = 31921;
      privateKeyFile = config.deployment.keys."wg-hass".path;
      peers = [
        {
          allowedIPs = nodes.futro.config.networking.wireguard.interfaces.hass.ips;
          publicKey = config.redacted.futro.wireguard.hass.publicKey;
        }
        {
          allowedIPs = [ "192.168.11.150/32" ];
          publicKey = config.redacted.phone.wireguard.hass.publicKey;
        }
      ];
    };
  };

  deployment.keys."wg-internal" = {
    destDir = "/";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/netcup01/wireguard/internal/privateKey" ];
  };

  deployment.keys."wg-hass" = {
    destDir = "/";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/netcup01/wireguard/hass/privateKey" ];
  };

  services.terraform-backend = {
    enable = true;
    extraEnvironment = {
      AUTH_BASIC_ENABLED = "true";
      LOCK_BACKEND = "local";
      STORAGE_BACKEND = "fs";
      STORAGE_FS_DIR = "./states";
      LISTEN_ADDR = "127.0.0.3:8080";
    };
    environmentFile = config.deployment.keys."terraform-backend_env".path;
    package = pkgs.callPackage ../packages/terraform-backend { };
  };

  deployment.keys."terraform-backend_env" = {
    destDir = "/";
    ## `KMS_KEY=<key>`
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/terraform-backend_env" ];
  };

  system.stateVersion = "22.05";
}
