## ntfy user add --role=admin <username>
## ntfy access '*' 'up*' write-only
{ ... }:

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
    };
  };

  systemd.services.ntfy-sh.serviceConfig.RuntimeDirectory = [ "ntfy-sh" ];
}
