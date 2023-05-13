{ config, ... }:

{
  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN = "https://vaultwarden.geklaute.cloud";
      IP_HEADER = "X-Forwarded-For";
      ROCKET_ADDRESS = "127.0.0.2";
      ROCKET_PORT = 3080;
      SIGNUPS_ALLOWED = false;
      TRASH_AUTO_DELETE_DAYS = 90;
      WEBSOCKET_ADDRESS = "127.0.0.2";
      WEBSOCKET_ENABLED = true;
      WEBSOCKET_PORT = 3012;
    };
    environmentFile = config.deployment.keys."vaultwarden_env".path;
  };

  deployment.keys."vaultwarden_env" = {
    destDir = "/";
    user = config.users.users.vaultwarden.name;
    ## `ADMIN_TOKEN=<actual token>`
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/vaultwarden_env" ];
  };
}
