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
      ips = [ "192.168.11.10/32" ];
      privateKeyFile = config.deployment.keys."wg-hass".path;
      peers = [
        {
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

  networking.firewall = {
    allowedTCPPorts = [
      8123 ## homeassistant
    ];
    interfaces.eth0.allowedTCPPorts = [
      1883 ## mqtt
    ];
  };

}
