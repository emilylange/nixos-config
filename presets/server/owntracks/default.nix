{ pkgs, lib, ... }:

{
  systemd.services.owntracks = {
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      User = "owntracks";
      DynamicUser = true;
      ExecStart = lib.getExe pkgs.owntracks-recorder + (toString [
        ""
        "--storage=%S/owntracks/store"
        "--port=0" # disable mqtt
        "--http-host=[::1]"

        # "--doc-root=/var/empty"
        # "--doc-root=${pkgs.owntracks-recorder.src}/docroot"
        "--doc-root=${pkgs.callPackage ../../../packages/owntracks-frontend {}}"
      ]);
      StateDirectory = "owntracks";
      WorkingDirectory = "%S/owntracks";

      CapabilityBoundingSet = [ "" ];
      DeviceAllow = [ "" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateMounts = true;
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
      RemoveIPC = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [ "@system-service" "~@privileged" "~@resources" "~@mount" ];
      UMask = "0077";
    };
  };
}
