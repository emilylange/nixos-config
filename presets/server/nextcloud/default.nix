{ pkgs, config, redacted, ... }:

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

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [{
      name = "nextcloud";
      ensureDBOwnership = true;
    }];
  };

  # ensure that postgres is running *before* running the setup
  systemd.services."nextcloud-setup" = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };
}
