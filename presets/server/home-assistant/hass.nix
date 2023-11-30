{ config, pkgs, ... }:

{
  services.home-assistant = {
    enable = true;
    extraPackages = python3Packages: with python3Packages; [ psycopg2 ];
    extraComponents = [
      "met"
      "lovelace"
      "mqtt"
      "backup"
      "esphome"
      "radio_browser" ## needed for onboarding
    ];
    config = {
      default_config = { };
      homeassistant = {
        unit_system = "metric";
        country = "!secret country";
        latitude = "!secret latitude";
        longitude = "!secret longitude";
        elevation = "!secret elevation";

        inherit (config.redacted.global.home-assistant) auth_providers;
      };
      recorder.db_url = "postgresql://@/hass";
      light = [
        {
          platform = "switch";
          name = "Klick-Klack";
          entity_id = "switch.main_switch";
        }
        {
          platform = "switch";
          name = "Bathroom";
          entity_id = "switch.bathroom_switch";
        }
        {
          platform = "switch";
          name = "Hallway";
          entity_id = "switch.hallway_switch";
        }
        {
          platform = "switch";
          name = "Kitchen";
          entity_id = "switch.kitchen_switch";
        }
      ];
    };
    customComponents = [
      (pkgs.fetchFromGitHub {
        owner = "zachowj";
        repo = "hass-node-red";
        rev = "v3.1.1";
        hash = "sha256-/DKjx4lXtr4QZq3wZwFwy8Q+094Cq5H6RsvEaswcCD8=";
      })
    ];
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [{
      name = "hass";
      ensureDBOwnership = true;
    }];
  };

  deployment.keys."secrets.yaml" = {
    destDir = config.services.home-assistant.configDir;
    keyCommand = [ "bw" "--nointeraction" "get" "notes" "gkcl/homeassistant/secrets.yaml" ];
    user = config.systemd.services.home-assistant.serviceConfig.User;
  };
  systemd.services.home-assistant.unitConfig.ConditionPathExists = [ config.deployment.keys."secrets.yaml".path ];
}
