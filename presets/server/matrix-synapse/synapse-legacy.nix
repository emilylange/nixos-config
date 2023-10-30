{ config, lib, pkgs, ... }:

{
  services.matrix-synapse = {
    enable = true;
    log.root.level = "WARNING";
    settings = {
      server_name = "matrix.geklautecloud.de";
      admin_contact = "mailto:matrix-synapse-admin@geklautecloud.de";
      signing_key_path = "${config.services.matrix-synapse.dataDir}/homeserver.signing.key";

      allow_public_rooms_without_auth = true;
      allow_public_rooms_over_federation = true;

      report_stats = true;
      enable_registration = false;
      allow_device_name_lookup_over_federation = false;

      max_upload_size = "100M";

      suppress_key_server_warning = true;
      trusted_key_servers = [
        { server_name = "indeednotjames.com"; }
        { server_name = "matrix.org"; }
      ];

      database.args = {
        user = "matrix-synapse";
        database = "matrix-synapse-legacy";
      };

      listeners = [{
        port = 28008;
        tls = false;
        type = "http";
        x_forwarded = true;
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
      config.deployment.keys."synapse-extraConf.json".path
    ];
  };

  ## CREATE USER "matrix-synapse";
  ## createdb --encoding=UTF8 --locale=C --template=template0 --owner=matrix-synapse matrix-synapse-legacy
  services.postgresql.enable = true;

  deployment.keys."synapse-extraConf.json" = {
    destDir = "/";
    keyCommand = [
      (lib.getExe pkgs.bash)
      "-c"
      ''
        jq -n \
          --arg "macaroon_secret_key" "$(bw --nointeraction get password gkcl/matrix.geklautecloud.de/macaroon)" \
          --arg "registration_shared_secret" "$(bw --nointeraction get password gkcl/matrix.geklautecloud.de/registration)" \
          --arg "turn_shared_secret" "$(bw --nointeraction get password gkcl/coturn_static-auth-secret)" \
          '{$macaroon_secret_key, $registration_shared_secret, $turn_shared_secret}'
      ''
    ];
    user = config.systemd.services.matrix-synapse.serviceConfig.User;
  };
}
