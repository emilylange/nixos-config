{ pkgs, config, redacted, ... }:

let
  dbUser = "drone";
  dbName = "drone";
in
{
  systemd.services.drone-server = {
    wantedBy = [ "multi-user.target" ];

    environment = {
      DRONE_GITEA_SERVER = "https://git.geklaute.cloud";

      DRONE_SERVER_HOST = "drone.geklaute.cloud";
      DRONE_SERVER_PROTO = "https";

      ## `DRONE_SERVER_PORT` isn't actually a port, but instead a full addr
      ## (which also explains why that "port" needs to be awkwardly prefixed with `:` like `:8080`)
      ## https://github.com/harness/drone/blob/3091e3916bd324c79fe28d1dc8f903e278387aac/cmd/drone-server/inject_server.go#L119
      DRONE_SERVER_PORT = "127.0.0.10:8080";

      DRONE_DATABASE_DATASOURCE = "user=${dbUser} host=/run/postgresql dbname=${dbName}";
      DRONE_DATABASE_DRIVER = "postgres";

      DRONE_DATADOG_ENABLED = "false";
      DRONE_JSONNET_ENABLED = "true";
      DRONE_STARLARK_ENABLED = "true";
      DRONE_LOGS_COLOR = "true";

      ## Process pending cron jobs more frequently (default 1h)
      DRONE_CRON_INTERVAL = "1m";

      inherit (redacted.kv.global.drone.server.env)
        AWS_REGION DRONE_S3_BUCKET DRONE_S3_ENDPOINT DRONE_USER_FILTER;
    };

    serviceConfig = {
      ExecStart = "${pkgs.drone}/bin/drone-server";
      User = dbUser;
      DynamicUser = true;
      EnvironmentFile = [
        config.deployment.keys."drone_additional_env".path
        config.deployment.keys."drone_rpc_secret_env".path
      ];

      ## Hardening
      CapabilityBoundingSet = [ "" ];
      DeviceAllow = [ "" ];
      LockPersonality = true;
      PrivateDevices = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProcSubset = "pid";
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectSystem = "strict";
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };

  services.postgresql = {
    enable = true;
    ensureUsers = [{
      name = dbUser;
      ensurePermissions = {
        "DATABASE ${dbName}" = "ALL PRIVILEGES";
      };
    }];
    ensureDatabases = [ dbName ];
  };

  deployment.keys."drone_additional_env" = {
    destDir = "/";
    ## ```env
    ## DRONE_GITEA_CLIENT_ID=
    ## DRONE_GITEA_CLIENT_SECRET=
    ## DRONE_COOKIE_SECRET=
    ## AWS_ACCESS_KEY_ID=
    ## AWS_SECRET_ACCESS_KEY=
    ## ```
    keyCommand = [ "bw" "--nointeraction" "get" "notes" "gkcl/drone_additional_env" ];
  };

  deployment.keys."drone_rpc_secret_env" = {
    destDir = "/";
    ## `DRONE_RPC_SECRET=<secret>`
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/drone_rpc_secret_env" ];
  };
}
