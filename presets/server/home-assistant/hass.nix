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

      http = {
        server_host = "::1";
        trusted_proxies = "::1";
        use_x_forwarded_for = true;
      };

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
    customComponents =
      let
        inherit (pkgs)
          buildHomeAssistantComponent
          fetchFromGitHub
          ;
        inherit (config.services.home-assistant.package.python.pkgs)
          defusedxml
          ;
      in
      [
        (buildHomeAssistantComponent rec {
          owner = "zachowj";
          domain = "nodered";
          version = "3.1.6";

          src = fetchFromGitHub {
            owner = "zachowj";
            repo = "hass-node-red";
            rev = "v${version}";
            hash = "sha256-ZeLxHnX7FPpHQ+CV1EiGQc9+jxY/+wYMk/d/6QdXji4=";
          };
        })

        (buildHomeAssistantComponent rec {
          owner = "hg1337";
          domain = "dwd";
          version = "2024.4.0";

          src = fetchFromGitHub {
            owner = "hg1337";
            repo = "homeassistant-dwd";
            rev = version;
            hash = "sha256-2bmLEBt6031p9SN855uunq7HrRJ9AFokw8t4CSBidTM=";
          };

          postPatch = ''
            substituteInPlace custom_components/dwd/manifest.json --replace-fail 'defusedxml==0.7.1' 'defusedxml==${defusedxml.version}'
          '';

          propagatedBuildInputs = [
            defusedxml
          ];
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
