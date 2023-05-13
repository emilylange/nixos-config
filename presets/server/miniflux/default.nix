{ pkgs, lib, ... }:

{
  services.miniflux = {
    enable = true;
    config = {
      BASE_URL = "https://rss.geklaute.cloud/";
      CLEANUP_ARCHIVE_READ_DAYS = "-1";
      CLEANUP_ARCHIVE_UNREAD_DAYS = "-1";
      CREATE_ADMIN = lib.mkForce "0";
      HTTP_CLIENT_TIMEOUT = "120";
      HTTPS = "1";
      LISTEN_ADDR = "/run/miniflux/miniflux.sock";
      POLLING_FREQUENCY = "20";
      POLLING_PARSING_ERROR_LIMIT = "-1";
      PROXY_IMAGES = "all";
      RUN_MIGRATIONS = "1";
    };
    adminCredentialsFile = pkgs.emptyFile;
  };

  systemd.services.miniflux.serviceConfig.RuntimeDirectoryMode = lib.mkForce "0755";
}
