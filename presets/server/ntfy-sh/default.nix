## ntfy user add --role=admin <username>
## ntfy access '*' 'up*' write-only
{ config, ... }:

{
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = "https://ntfy.geklaute.cloud";
      behind-proxy = true;
      listen-http = "";
      listen-unix = "/run/ntfy-sh/ntfy.sock";
      listen-unix-mode = 511; ## lossy nix->yaml conversion eats octal literals (equal to 0777)

      auth-file = "/var/lib/ntfy-sh/user.db";
      auth-default-access = "deny-all";
      cache-file = "/var/lib/ntfy-sh/cache.db";
      cache-duration = "72h";

      enable-signup = false;
      visitor-email-limit-burst = 0;
    };
  };

  systemd.services.ntfy-sh = {
    serviceConfig = {
      RuntimeDirectory = [ "ntfy-sh" ];
      EnvironmentFile = config.deployment.keys."ntfy_additional_env".path;
    };
    unitConfig.ConditionPathExists = [ config.deployment.keys."ntfy_additional_env".path ];
  };

  deployment.keys."ntfy_additional_env" = {
    destDir = "/";
    ## ```env
    ## NTFY_SMTP_SENDER_ADDR=
    ## NTFY_SMTP_SENDER_USER=
    ## NTFY_SMTP_SENDER_PASS=
    ## NTFY_SMTP_SENDER_FROM=
    ## ```
    keyCommand = [ "bw" "--nointeraction" "get" "notes" "gkcl/ntfy_additional_env" ];
  };
}
