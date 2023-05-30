{ config, pkgs, modulesPath, nodes, self, ... }:

{
  imports = [
    ../presets/common/docker
    ../presets/server/caddy
    ../presets/server/coturn
    ../presets/server/drone
    ../presets/server/drone/server
    ../presets/server/gitea
    ../presets/server/miniflux
    ../presets/server/ntfy-sh
    ../presets/server/uptime-kuma
    ../presets/server/vaultwarden
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  networking.interfaces.eth0.ipv4.addresses = [{
    address = "2.56.98.73";
    prefixLength = 22;
  }];

  networking.defaultGateway = {
    address = "2.56.96.1";
    interface = "eth0";
  };

  networking.interfaces.eth0.ipv6.addresses = [{
    address = "2a03:4000:3e:1f8::1";
    prefixLength = 64;
  }];

  networking.defaultGateway6 = {
    address = "fe80::1";
    interface = "eth0";
  };

  networking.nat64 = {
    enable = true;
    subnet = "2a03:4000:3e:1f8:46::/96";
    allowlist = [
      nodes.stardust.config.networking.clat.ipv6
    ];
  };

  boot = {
    growPartition = true;
    kernelParams = [ "console=ttyS0" ];
    loader.grub.device = "/dev/vda"; ## requires driver to be set to virtio in netcup dashboard
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [
      "subvol=@"
      "noatime"
      "compress-force=zstd"
    ];
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
