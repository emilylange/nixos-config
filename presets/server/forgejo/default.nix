{ pkgs, config, lib, ... }:

let
  cfg = config.services.forgejo;
in
{
  services.forgejo = {
    enable = true;

    database = {
      type = "postgres";
      createDatabase = true;
    };

    lfs.enable = true;

    settings = {
      DEFAULT = {
        APP_NAME = "Geklautecloud";
      };

      "ui.meta" = {
        AUTHOR = "Geklautecloud";
        DESCRIPTION = "A tiny Forgejo instance";
        KEYWORDS = "git";
      };

      ## cookies
      security.COOKIE_REMEMBER_NAME = "etc_name";
      security.COOKIE_USERNAME = "usr_name";
      security.LOGIN_REMEMBER_DAYS = 30;
      session.COOKIE_NAME = "usr_session";
      session.COOKIE_SECURE = true;
      session.PROVIDER = "file";

      ## ssh
      server = {
        PROTOCOL = "http+unix";
        ROOT_URL = "https://git.geklaute.cloud/";
        DOMAIN = "git.geklaute.cloud";
        BUILTIN_SSH_SERVER_USER = "git";
        SSH_PORT = 22;
        SSH_SERVER_HOST_KEYS = "ssh/ssh_host_ed25519_key,ssh/ssh_host_rsa_key";
        START_SSH_SERVER = true;
      };

      "repository.signing" = {
        CRUD_ACTIONS = "always";
        INITAL_COMMIT = "always";
        MERGES = "always";
        WIKI = "always";

        ## gpg --homedir /var/lib/forgejo/data/home/.gnupg
        SIGNING_EMAIL = "noreply@git.geklaute.cloud";
        SIGNING_KEY = "0361BCFE4CB85DA6";
        SIGNING_NAME = "git.geklaute.cloud";
      };

      "cron.update_checker".ENABLED = true;

      mailer = {
        ENABLED = true;
        FROM = "noreply.git@geklaute.cloud";
        PROTOCOL = "smtps";
        SEND_AS_PLAIN_TEXT = true;
      };

      openid = {
        ENABLE_OPENID_SIGNIN = false;
        ENABLE_OPENID_SIGNUP = false;
      };

      other = {
        SHOW_FOOTER_BRANDING = false;
        SHOW_FOOTER_VERSION = true;
      };

      service = {
        CAPTCHA_TYPE = "hcaptcha";
        ENABLE_CAPTCHA = true;
        REQUIRE_EXTERNAL_REGISTRATION_CAPTCHA = true;

        ENABLE_NOTIFY_MAIL = true;
        DEFAULT_KEEP_EMAIL_PRIVATE = true;

        REGISTER_EMAIL_CONFIRM = true;
      };

      indexer.REPO_INDEXER_ENABLED = true;
      server.OFFLINE_MODE = true;
      log.LEVEL = "Warn";
      security.REVERSE_PROXY_TRUSTED_PROXIES = "192.168.0.0/16,172.16.0.0/12,10.0.0.0/8,127.0.0.1/8,fd00::/8,::1";
    };

    secrets = {
      mailer = {
        PASSWD = "${cfg.customDir}/conf/_mailer_pw";
        SMTP_ADDR = "${cfg.customDir}/conf/_mailer_host";
        USER = "${cfg.customDir}/conf/_mailer_user";
      };

      service = {
        HCAPTCHA_SECRET = "${cfg.customDir}/conf/_hcaptcha_secret";
        HCAPTCHA_SITEKEY = "${cfg.customDir}/conf/_hcaptcha_sitekey";
      };
    };
  };

  systemd.tmpfiles.rules =
    let
      robots = pkgs.writeText "robots.txt" ''
        User-agent: *
        Disallow: /
      '';
    in
    [
      "L+ '${cfg.stateDir}/custom/assets/robots.txt' - - - - ${robots}"
    ];

  systemd.services.forgejo = {
    serviceConfig = lib.optionalAttrs (cfg.settings.server.SSH_PORT < 1024) {
      AmbientCapabilities = lib.mkForce "CAP_NET_BIND_SERVICE";
      CapabilityBoundingSet = lib.mkForce "CAP_NET_BIND_SERVICE";
      PrivateUsers = lib.mkForce false;
    };
  };

  networking.firewall.allowedTCPPorts = [
    cfg.settings.server.SSH_PORT
  ];
}
