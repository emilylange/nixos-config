{ lib
, config
, pkgs
, ...
}:

let
  cfg = config.less.mautrix-whatsapp;
  db = "mautrixwhatsapp";
in
{
  options.less.mautrix-whatsapp = with lib; {
    enable = mkEnableOption "mautrix-whatsapp";

    package = mkPackageOptionMD pkgs "mautrix-whatsapp" { };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.mautrix-whatsapp = {
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      serviceConfig = {
        Type = "exec";
        User = "mautrix-whatsapp";
        ExecStart = "${lib.getExe cfg.package} --no-update";
        WorkingDirectory = "/var/lib/mautrix-whatsapp";

        StateDirectory = "mautrix-whatsapp";
        Restart = "on-failure";
        RestartSec = "30s";

        NoNewPrivileges = "yes";
        MemoryDenyWriteExecute = true;
        PrivateDevices = "yes";
        PrivateTmp = "yes";
        ProtectHome = "yes";
        ProtectSystem = "strict";
        ProtectControlGroups = "true";
        RestrictSUIDSGID = true;
        RestrictRealtime = true;
        LockPersonality = true;
        ProtectKernelLogs = true;
        ProtectKernelTunables = true;
        ProtectHostname = true;
        ProtectKernelModules = true;
        PrivateUsers = true;
        ProtectClock = true;
        SystemCallArchitectures = "native";
        SystemCallErrorNumber = "EPERM";
        SystemCallFilter = "@system-service";
      };
    };

    users = {
      users.mautrix-whatsapp = {
        isSystemUser = true;
        home = "/var/lib/mautrix-whatsapp";
        group = "mautrix-whatsapp";
      };
      groups."mautrix-whatsapp" = { };
    };

    services.postgresql = {
      enable = true;
      ensureDatabases = [ db ];
      ensureUsers = [{
        name = config.systemd.services.mautrix-whatsapp.serviceConfig.User;
        ensureDBOwnership = true;
      }];
    };
  };

}
