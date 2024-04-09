{ pkgs, ... }:

{
  services.garage = {
    enable = true;
    package = pkgs.garage_0_9;
    logLevel = "info";
    settings = {
      replication_mode = "none";
      db_engine = "lmdb";
      metadata_dir = "/ext4/garage/meta";
      data_dir = "/var/lib/garage/data";
      compression_level = "none"; # underlying btrfs is mounted with -o compress-force=zstd
      rpc_bind_addr = "127.3.3.3:3901";

      s3_api = {
        api_bind_addr = "127.3.3.3:3333";
        s3_region = "garage";
      };
    };

    extraEnvironment = {
      GARAGE_RPC_SECRET_FILE = "%d/rpc-secret";
      # Workaround for "Error: File /run/credentials/garage.service/rpc-secret is world-readable! (mode: 0100440, expected 0600)"
      # systemd upstream issue: https://github.com/systemd/systemd/issues/29435
      # garage: https://git.deuxfleurs.fr/Deuxfleurs/garage/issues/658
      GARAGE_ALLOW_WORLD_READABLE_SECRETS = "true";
    };
  };

  systemd.services.garage.serviceConfig.LoadCredential = [
    "rpc-secret:/garage_rpc_secret" # openssl rand -hex 32
  ];

  systemd.services.garage.serviceConfig = {
    DynamicUser = false;
    Group = "garage";
    User = "garage";
  };

  systemd.tmpfiles.settings."10-garage" = {
    "/ext4/garage/meta".d = {
      group = "garage";
      mode = "0700";
      user = "garage";
    };
  };

  users.users.garage = {
    description = "Garage Service";
    home = "/var/lib/garage";
    group = "garage";
    isSystemUser = true;
  };
  users.groups.garage = { };
}
