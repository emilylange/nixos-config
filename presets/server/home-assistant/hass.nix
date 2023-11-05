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
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "hass" ];
    ensureUsers = [{
      name = "hass";
      ensurePermissions = {
        "DATABASE hass" = "ALL PRIVILEGES";
      };
    }];
  };

  systemd.tmpfiles.rules =
    let
      node-red = pkgs.fetchFromGitHub
        {
          owner = "zachowj";
          repo = "hass-node-red";
          rev = "v1.2.0";
          hash = "sha256-EaPkyHqbKQJbsFkI2FNTTq3E9q3JJN1KhhLlTDr2mpw=";
        } + "/custom_components/nodered";
    in
    [
      "L+ '${config.services.home-assistant.configDir}/custom_components/nodered' - - - - ${node-red}"
    ];

  deployment.keys."secrets.yaml" = {
    destDir = config.services.home-assistant.configDir;
    keyCommand = [ "bw" "--nointeraction" "get" "notes" "gkcl/homeassistant/secrets.yaml" ];
    user = config.systemd.services.home-assistant.serviceConfig.User;
  };
  systemd.services.home-assistant.unitConfig.ConditionPathExists = [ config.deployment.keys."secrets.yaml".path ];
}
