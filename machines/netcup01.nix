{ config, pkgs, modulesPath, nodes, ... }:

let
  wg-ipv4-port = 51825;
in
{
  imports = [
    ../presets/common/docker
    ../presets/server/coturn
    "${modulesPath}/profiles/qemu-guest.nix"
  ];

  networking.useDHCP = false;
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

      "20-wireguard-ipv4" = {
        matchConfig.Name = "wg-ipv4";
        address = [ "192.168.178.1/24" ];
        networkConfig = {
          IPMasquerade = "ipv4";
          IPForward = true;
        };
      };
    };

    netdevs = {
      "20-wireguard-ipv4" = {
        netdevConfig = {
          Kind = "wireguard";
          Name = "wg-ipv4";
        };

        wireguardConfig = {
          PrivateKeyFile = config.deployment.keys."wg-ipv4".path;
          ListenPort = wg-ipv4-port;
        };

        wireguardPeers = [
          {
            wireguardPeerConfig = {
              PublicKey = config.redacted.wip.wireguard.ipv4.publicKey;
              AllowedIPs = [ "192.168.178.2" ];
            };
          }
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
      options = [
        "umask=0077"
      ];
    };
  };

  ## forgejo's internal ssh server (which we port forward) runs on :22
  services.openssh.ports = [ 22222 ];

  zramSwap = {
    enable = true;
    memoryPercent = 10;
  };
  services.qemuGuest.enable = true;

  networking.firewall =
    let
      external-ipv4 = "2.56.98.73";
      internal-interface = "wg-ipv4";
      target-ipv4 = "192.168.178.2";
    in
    {
      extraCommands = ''
        iptables -t nat -A PREROUTING -i ${internal-interface} -j MARK --set-mark 1
        iptables -t nat -A PREROUTING -d ${external-ipv4}/32 -p tcp --dport 22 -j DNAT --to-destination ${target-ipv4}
        iptables -t nat -A PREROUTING -d ${external-ipv4}/32 -p tcp --dport 80 -j DNAT --to-destination ${target-ipv4}
        iptables -t nat -A PREROUTING -d ${external-ipv4}/32 -p tcp --dport 443 -j DNAT --to-destination ${target-ipv4}
        iptables -t nat -A PREROUTING -d ${external-ipv4}/32 -p udp --dport 443 -j DNAT --to-destination ${target-ipv4}

        iptables -t nat -A POSTROUTING -o ${internal-interface} -m mark --mark 1 -j SNAT --to-source ${external-ipv4}

        iptables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
      '';

      extraStopCommands = ''
        iptables -t nat -D PREROUTING -i ${internal-interface} -j MARK --set-mark 1
        iptables -t nat -D PREROUTING -d ${external-ipv4}/32 -p tcp --dport 22 -j DNAT --to-destination ${target-ipv4}
        iptables -t nat -D PREROUTING -d ${external-ipv4}/32 -p tcp --dport 80 -j DNAT --to-destination ${target-ipv4}
        iptables -t nat -D PREROUTING -d ${external-ipv4}/32 -p tcp --dport 443 -j DNAT --to-destination ${target-ipv4}
        iptables -t nat -D PREROUTING -d ${external-ipv4}/32 -p udp --dport 443 -j DNAT --to-destination ${target-ipv4}

        iptables -t nat -D POSTROUTING -o ${internal-interface} -m mark --mark 1 -j SNAT --to-source ${external-ipv4}

        iptables -t mangle -D FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
      '';

      allowedUDPPorts = [
        config.networking.wireguard.interfaces.hass.listenPort
        wg-ipv4-port
      ];
    };

  networking.wireguard.interfaces = {
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

  deployment.keys."wg-hass" = {
    destDir = "/";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/netcup01/wireguard/hass/privateKey" ];
  };

  deployment.keys."wg-ipv4" = {
    destDir = "/";
    user = "systemd-network";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/netcup01/wireguard/ipv4/privateKey" ];
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
