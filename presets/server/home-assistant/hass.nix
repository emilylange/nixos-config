{ config, pkgs, ... }:

{
  services.home-assistant = {
    enable = true;
    package = (pkgs.home-assistant.override {
      extraPackages = python3Packages: with python3Packages; [ psycopg2 ];
      extraComponents = [
        "met"
        "lovelace"
        "mqtt"
        "backup"
        "esphome"
        "radio_browser" ## needed for onboarding
      ];
    }).overrideAttrs (_: { doInstallCheck = false; });
    config = {
      # As there isn't an official way to blocklist certain integrations that get enabled
      # when using `default_config = { };`, we have to maintain an allowlist instead.
      # https://www.home-assistant.io/integrations/default_config/
      config = { };
      frontend = { };
      history = { };
      logbook = { };
      logger = { };
      mobile_app = { };
      my = { };
      person = { };
      sun = { };
      system_health = { };

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
        rev = "v3.1.6";
        hash = "sha256-ZeLxHnX7FPpHQ+CV1EiGQc9+jxY/+wYMk/d/6QdXji4=";
      })
      (pkgs.fetchFromGitHub {
        owner = "hg1337";
        repo = "homeassistant-dwd";
        rev = "2024.4.0";
        hash = "sha256-2bmLEBt6031p9SN855uunq7HrRJ9AFokw8t4CSBidTM=";
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
