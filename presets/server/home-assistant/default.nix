{ config, pkgs, lib, ... }:

{
  imports = [
    ./hass.nix
    ./mqtt.nix
    ./node-red.nix
    ./zigbee2mqtt.nix
  ];

  networking.wireguard.interfaces = {
    hass = {
      ips = [
        "fd64:aaaa:aaaa::/128"
        "2a01:4f8:190:441a:aaaa:aaaa:aaaa:aaaa/128"
      ];
      listenPort = 54940;
      privateKeyFile = config.deployment.keys."wg-hass".path;
      peers = [
        {
          allowedIPs = [ "fd64:aaaa:aaaa::6666/128" ];
          endpoint = "[2a01:4f8:190:441a::ffff]:31921";
          publicKey = "xFeQuWKTFuMnfGG0nB6KR6VzV1t7BIYxZ0mAkUIqaFw=";
          persistentKeepalive = 25;
        }
      ] ++ config.redacted.global.home-assistant.wireguard.peers;
    };
  };

  services.caddy = {
    enable = true;
    package = pkgs.callPackage ../../../packages/caddy { };
    configFile = pkgs.writeTextDir "Caddyfile" ''
      {
        grace_period 10s
      }

      (defaults) {
        encode zstd gzip

        header Strict-Transport-Security "max-age=31536000; includeSubDomains"
        header X-Powered-By "trans rights are human rights"

        @X-Clacks-Overhead header X-Clacks-Overhead *
        header @X-Clacks-Overhead X-Clacks-Overhead {http.request.header.X-Clacks-Overhead}

        handle_path /.well-known/security.txt {
          respond `${lib.readFile ../caddy/security.txt}`
        }
      }

      emily.town *.emily.town {
        import defaults

        tls {
          dns acmedns /caddy_acmedns_emily.town.json
          propagation_timeout -1
        }

        # punycode for "höme"
        @home host xn--hme-sna.emily.town
        handle @home {
          reverse_proxy http://[::1]:8123
        }

        # punycode for "öwnträcks"
        @owntracks host xn--wntrcks-8wa1n.emily.town
        handle @owntracks {
          reverse_proxy http://[::1]:8083
        }

        handle {
          redir https://emily.town
        }
      }

    '' + /Caddyfile;
  };

  deployment.keys."wg-hass" = {
    destDir = "/";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/futro/wireguard/hass/privateKey" ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      80 # caddy
      443 # caddy
    ];
    allowedUDPPorts = [
      443 # caddy
      54940 # wireguard
    ];
    interfaces.eth0.allowedTCPPorts = [
      1883 # mqtt
    ];
  };

}
