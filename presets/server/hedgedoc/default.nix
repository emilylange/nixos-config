{ config, ... }:

{
  services.hedgedoc = {
    enable = true;

    settings = {
      db = {
        username = "hedgedoc";
        database = "hedgedoc";
        host = "/run/postgresql";
        dialect = "postgresql";
      };
      path = "/run/hedgedoc/hedgedoc.sock";
      domain = "hedgedoc.geklaute.cloud";
      protocolUseSSL = true;
      hsts.enable = true;

      loglevel = "warn";

      email = false;
      allowAnonymous = false;
      allowAnonymousEdits = true;
      allowEmailRegister = false;
      allowGravatar = false;
      defaultPermission = "private";

      oauth2 = {
        providerName = "git.geklaute.cloud";
        authorizationURL = "https://git.geklaute.cloud/login/oauth/authorize";
        tokenURL = "https://git.geklaute.cloud/login/oauth/access_token";
        userProfileURL = "https://git.geklaute.cloud/login/oauth/userinfo";
        userProfileDisplayNameAttr = "name";
        userProfileEmailAttr = "email";
        userProfileIdAttr = "sub";
        userProfileUsernameAttr = "preferred_username";
        scope = "openid"; # scope don't seem to be implemented in forgejo :(
        # clientID = ""; # provided via .env
        # clientSecret = ""; # provided via .env
      };
      # sessionSecret = ""; # provided via .env
    };

    environmentFile = "/hedgedoc.env";
  };

  # dumb fix for unix socket permissions
  systemd.services.hedgedoc.postStart = ''
    until [ -S "${config.services.hedgedoc.settings.path}" ]; do
      sleep 0.5
    done
    chmod ugo=w "${config.services.hedgedoc.settings.path}"
  '';

  services.postgresql = {
    ensureDatabases = [ "hedgedoc" ];
    ensureUsers = [{
      name = "hedgedoc";
      ensureDBOwnership = true;
    }];
  };
}
