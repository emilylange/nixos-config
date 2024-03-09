{ config, lib, pkgs, ... }:

let
  hostConf = config;
in
{
  containers."mx-synapse-indeednotjames" = {
    autoStart = true;
    privateNetwork = false;
    bindMounts = {
      ${hostConf.deployment.keys."mx-synapse.indeednotjames.com-extraConf.json".path} = {
        hostPath = hostConf.deployment.keys."mx-synapse.indeednotjames.com-extraConf.json".path;
        isReadOnly = true;
      };

      "host-postgres-unix" = {
        hostPath = "/run/postgresql";
        mountPoint = "/run/postgresql";
        isReadOnly = true;
      };

      "container-matrix-synapse-unix" = {
        hostPath = "/run/matrix-synapse-indeednotjames";
        mountPoint = "/run/matrix-synapse";
        isReadOnly = false;
      };
    };

    config = { config, ... }: {
      services.matrix-synapse = {
        enable = true;
        enableRegistrationScript = false;
        log.root.level = "WARNING";
        settings = {
          server_name = "indeednotjames.com";
          admin_contact = "mailto:matrix-synapse-admin@indeednotjames.com";
          signing_key_path = "${config.services.matrix-synapse.dataDir}/homeserver.signing.key";

          allow_public_rooms_without_auth = true;
          allow_public_rooms_over_federation = true;

          report_stats = true;
          enable_registration = false;
          allow_device_name_lookup_over_federation = false;

          max_upload_size = "100M";

          suppress_key_server_warning = true;
          trusted_key_servers = [
            { server_name = "matrix.geklautecloud.de"; }
            { server_name = "matrix.org"; }
          ];

          ## createuser matrix-synapse
          ## createdb --encoding=UTF8 --locale=C --template=template0 --owner=matrix-synapse matrix-synapse-indeednotjames
          database.args = {
            user = "matrix-synapse";
            database = "matrix-synapse-indeednotjames";
          };

          listeners = [{
            path = "/run/matrix-synapse/public.sock";
            mode = "0222";
            type = "http";
            resources = [{
              compress = false;
              names = [
                "client"
                "federation"
              ];
            }];
          }];

          turn_user_lifetime = "1h";
          turn_uris = [
            "turn:turn.geklaute.cloud:3478?transport=tcp"
          ];

          url_preview_enabled = true;
          url_preview_ip_range_blacklist = [
            "10.0.0.0/8"
            "100.64.0.0/10"
            "127.0.0.0/8"
            "169.254.0.0/16"
            "172.16.0.0/12"
            "192.0.0.0/24"
            "192.0.2.0/24"
            "192.168.0.0/16"
            "192.88.99.0/24"
            "198.18.0.0/15"
            "198.51.100.0/24"
            "2001:db8::/32"
            "203.0.113.0/24"
            "224.0.0.0/4"
            "::1/128"
            "fc00::/7"
            "fe80::/10"
            "fec0::/10"
            "ff00::/8"
          ];

          push.include_content = false;

          experimental_features = {
            ## https://github.com/matrix-org/synapse/pull/11507
            msc3266_enabled = true;
          };
        };

        extraConfigFiles = [
          hostConf.deployment.keys."mx-synapse.indeednotjames.com-extraConf.json".path
        ];
      };

      networking.hostName = "mx-synapse-indeednotjames";
      nixpkgs.pkgs = pkgs;
      system.stateVersion = "22.11";
    };
  };

  deployment.keys."mx-synapse.indeednotjames.com-extraConf.json" = {
    destDir = "/";
    keyCommand = [
      (lib.getExe pkgs.bash)
      "-c"
      ''
        jq -n \
          --arg "macaroon_secret_key" "$(bw --nointeraction get password gkcl/mx-synapse.indeednotjames.com/macaroon)" \
          --arg "registration_shared_secret" "$(bw --nointeraction get password gkcl/mx-synapse.indeednotjames.com/registration)" \
          --arg "turn_shared_secret" "$(bw --nointeraction get password gkcl/coturn_static-auth-secret)" \
          '{$macaroon_secret_key, $registration_shared_secret, $turn_shared_secret}'
      ''
    ];
    user = config.containers."mx-synapse-indeednotjames".config.systemd.services.matrix-synapse.serviceConfig.User;
  };

  # We depend on `/run/postgresql` (RuntimeDirectory) as part of a bindMount in the container.
  # We do not want that directory gone (or rather recreated) if `postgresql.service` restarts
  # (which might happens for various reasons), as this would change `/run/postgresql` inode,
  # which isn't populated to the bindMount, which in turn results in a broken (empty) bind state.
  systemd.services.postgresql.serviceConfig.RuntimeDirectoryPreserve = true;

  systemd.tmpfiles.settings."10-nixos-container-indeednotjames" = {
    "/run/matrix-synapse-indeednotjames".d = {
      mode = "0755";
    };
  };
}
