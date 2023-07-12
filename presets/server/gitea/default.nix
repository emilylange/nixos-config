{ pkgs, config, lib, ... }:

let
  sshPort = config.services.gitea.settings.server.SSH_PORT;
in
{
  services.gitea = {
    enable = true;

    package = pkgs.forgejo.override {
      buildGoModule = args: pkgs.buildGoModule (args // {
        subPackages = [ "." "contrib/environment-to-ini" ];
      });
    };

    appName = "Geklautecloud";

    database = {
      type = "postgres";
      createDatabase = true;
      passwordFile = config.deployment.keys."gitea_database-pw".path;
    };

    mailerPasswordFile = config.deployment.keys."gitea_mailer-pw".path;

    lfs.enable = true;

    settings = {
      "ui.meta" = {
        AUTHOR = "Geklautecloud";
        DESCRIPTION = "A tiny Gitea/Forgejo instance";
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

        ## gpg --homedir /var/lib/gitea/data/home/.gnupg
        SIGNING_EMAIL = "noreply@git.geklaute.cloud";
        SIGNING_KEY = "0361BCFE4CB85DA6";
        SIGNING_NAME = "git.geklaute.cloud";
      };

      "cron.update_checker".ENABLED = true;

      mailer = {
        ENABLED = true;
        FROM = "noreply.gitea@geklaute.cloud";
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
  };

  systemd.tmpfiles.rules =
    let
      robots = pkgs.writeText "robots.txt" ''
        User-agent: *
        Disallow: /
      '';
      droneHost = config.systemd.services.drone-server.environment.DRONE_SERVER_HOST;
      templates = pkgs.writeTextDir "custom/extra_tabs.tmpl" ''
        <a class="item" href="https://${droneHost}{{$.RepoLink}}" target="_blank" rel="noopener noreferrer">
          <img alt="DroneCI status badge" src="https://${droneHost}/api/badges{{$.RepoLink}}/status.svg">
        </a>
      '';
    in
    [
      "L+ '${config.services.gitea.stateDir}/custom/robots.txt' - - - - ${robots}"
      "L+ '${config.services.gitea.stateDir}/custom/templates' - - - - ${templates}"
    ];

  systemd.services.gitea = {
    serviceConfig = {
      ## GITEA__SECTION_NAME__KEY_NAME
      ## Escape `.` with `_0X2E_`
      ## Escape `-` with `_0X2D_`
      ## See https://github.com/go-gitea/gitea/tree/main/contrib/environment-to-ini
      ## and https://docs.gitea.io/en-us/install-with-docker/#managing-deployments-with-environment-variables
      EnvironmentFile = config.deployment.keys."gitea_additional_env".path;
      ## TODO: remove when https://github.com/NixOS/nixpkgs/pull/242863 is resolved
      RuntimeDirectoryMode = lib.mkForce "0755";
    } // lib.optionalAttrs (sshPort < 1024) {
      AmbientCapabilities = lib.mkForce "CAP_NET_BIND_SERVICE";
      CapabilityBoundingSet = lib.mkForce "CAP_NET_BIND_SERVICE";
      PrivateUsers = lib.mkForce false;
    };

    ## incredible hacky way to use `environment-to-ini` in preStart
    preStart = lib.mkBefore ''
      function chmod {
        if [[ "$1" == "u-w" ]]; then
          echo "Running environment-to-ini..."
          ${config.services.gitea.package}/bin/environment-to-ini --config "$2"
        fi

        ## run original command
        command chmod "$@"
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [
    sshPort
  ];

  deployment.keys."gitea_database-pw" = {
    user = config.services.gitea.user;
    destDir = "/";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/gitea_database-pw" ];
  };

  deployment.keys."gitea_mailer-pw" = {
    user = config.services.gitea.user;
    destDir = "/";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/gitea_mailer-pw" ];
  };

  deployment.keys."gitea_additional_env" = {
    user = config.services.gitea.user;
    destDir = "/";
    ## ```env
    ## GITEA__mailer__HOST=
    ## GITEA__mailer__USER=
    ## GITEA__service__HCAPTCHA_SECRET=
    ## GITEA__service__HCAPTCHA_SITEKEY=
    ## ```
    keyCommand = [ "bw" "--nointeraction" "get" "notes" "gkcl/gitea_additional_env" ];
  };
}
