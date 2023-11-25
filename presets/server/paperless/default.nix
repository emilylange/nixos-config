## requires a superuser to be manually setup using
## `${dataDir}/paperless-manage createsuperuser`
{ config, ... }:

let
  db = "paperless";
in
{
  services.paperless = {
    enable = true;
    dataDir = "/paperless";
    extraConfig = {
      PAPERLESS_OCR_LANGUAGE = "deu+eng";
      PAPERLESS_DBHOST = "/run/postgresql";
      PAPERLESS_DBENGINE = "postgresql";
      PAPERLESS_DBNAME = db;
      ## TODO: set PAPERLESS_SECRET_KEY

      PAPERLESS_ENABLE_UPDATE_CHECK = false;
      PAPERLESS_TASK_WORKERS = 1;
      PAPERLESS_THREADS_PER_WORKER = 1;
      PAPERLESS_WORKER_TIMEOUT = 3600;
      PAPERLESS_CONVERT_MEMORY_LIMIT = 128;
    };
  };

  services.postgresql = {
    enable = true;
    ensureDatabases = [ db ];
    ensureUsers = [{
      name = config.services.paperless.user;
      ensureDBOwnership = true;
    }];
  };
}
