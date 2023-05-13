{ config, ... }:

{
  services.zigbee2mqtt = {
    enable = true;
    settings = {
      homeassistant = config.services.home-assistant.enable;
      permit_join = false;
      serial.port = "/dev/serial/by-id/usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_f87f93def13aec11b7eda4957a0af07f-if00-port0";
      mqtt = {
        base_topic = "zigbee2mqtt";
        server = "mqtt://localhost/1883";
      };
      advanced = {
        network_key = "!secret.yaml network_key";
        homeassistant_legacy_entity_attributes = false;
        legacy_api = false;
      };
      frontend = {
        auth_token = "!secret.yaml auth_token";
        port = 8881;
      };
    };
  };

  deployment.keys."secret.yaml" = {
    destDir = config.services.zigbee2mqtt.dataDir;
    user = config.systemd.services.zigbee2mqtt.serviceConfig.User;
    keyCommand = [ "bw" "--nointeraction" "get" "notes" "gkcl/zigbee2mqtt/secret.yaml" ];
  };
}
