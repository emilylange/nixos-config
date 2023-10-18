{ pkgs, config, lib, redacted, ... }:

{
  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud27;

    https = true;
    hostName = "geklaute.cloud";
    maxUploadSize = "10G"; ## nextcloud's current s3 implementation requires the *whole* file to be loaded in RAM before uploading it to s3

    appstoreEnable = false;

    caching = {
      redis = true;
      memcached = true;
      apcu = false;
    };

    config = {
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbhost = "/run/postgresql";

      defaultPhoneRegion = "DE";
      trustedProxies = [ "192.168.178.1/24" ];

      adminuser = "admin";
      adminpassFile = config.deployment.keys."nextcloud-adminpass".path;

      objectstore.s3 = {
        enable = true;
        autocreate = true;
        inherit (redacted.kv.global.nextcloud.objectstore.s3)
          bucket hostname key region;
        secretFile = config.deployment.keys."nextcloud-s3-secretkey".path;
      };
    };

    globalProfiles = false;
    enableImagemagick = false;
  };

  systemd.services.nextcloud-previewgenerator = {
    serviceConfig.Type = "oneshot";
    serviceConfig.ExecStart = "${config.services.nextcloud.occ}/bin/nextcloud-occ preview:pre-generate";
    serviceConfig.User = "nextcloud";
    startAt = "*:0/10";
  };

  services.redis.servers.nextcloud = {
    user = "nextcloud";
    enable = true;
  };

  deployment.keys."nextcloud-adminpass" = {
    user = "nextcloud";
    destDir = "/";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/nextcloud-adminpass" ];
  };

  deployment.keys."nextcloud-s3-secretkey" = {
    user = "nextcloud";
    destDir = "/";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/nextcloud-s3-secretkey" ];
  };

  ## we will use caddy instead :)
  services.nginx.enable = false;

  services.phpfpm.pools.nextcloud.settings = {
    "listen.owner" = config.services.caddy.user;
    "listen.group" = config.services.caddy.group;
  };

  services.caddy = {
    enable = true;
    configFile = pkgs.writeTextDir "Caddyfile" ''
      ${config.services.nextcloud.hostName} {
        bind ${lib.head (lib.splitString "/" (lib.head config.networking.wireguard.interfaces.internal.ips))}
        tls internal

        log
        header -Server

        @forbidden {
          path /.htaccess /.user.ini
          path /3rdparty*
          path /AUTHORS /COPYING /README
          path /build*
          path /config*
          path /console.php
          path /data*
          path /lib*
          path /occ*
          path /templates*
          path /tests*
        }
        redir @forbidden https://geklaute.cloud/login

        file_server
        root * ${config.services.nextcloud.package}
        php_fastcgi unix/${config.services.phpfpm.pools.nextcloud.socket} {
          ## hide index.php from uri
          env front_controller_active true

          trusted_proxies 192.168.178.1/24
          header_down Strict-Transport-Security "max-age=15552000;"
        }

        rewrite /.well-known/carddav /remote.php/dav
        rewrite /.well-known/caldav /remote.php/dav
      }
    '' + /Caddyfile;
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [
      "nextcloud"
    ];
    ensureUsers = [{
      name = "nextcloud";
      ensurePermissions."DATABASE nextcloud" = "ALL PRIVILEGES";
    }];
  };

  # ensure that postgres is running *before* running the setup
  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  networking.firewall.interfaces.internal.allowedTCPPorts = [
    80
    443
  ];
}
