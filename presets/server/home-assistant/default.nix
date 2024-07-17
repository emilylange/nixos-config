{ config, nodes, ... }:

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

  deployment.keys."wg-hass" = {
    destDir = "/";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/futro/wireguard/hass/privateKey" ];
  };

  networking.firewall = {
    allowedTCPPorts = [
      8123 ## homeassistant
    ];
    allowedUDPPorts = [
      54940 # wireguard
    ];
    interfaces.eth0.allowedTCPPorts = [
      1883 ## mqtt
    ];
  };

}
