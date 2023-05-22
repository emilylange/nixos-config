{ lib, pkgs, config, ... }:

{
  systemd.services.drone-runner-exec = {
    wantedBy = [ "multi-user.target" ];

    environment = {
      DRONE_LIMIT_REPOS = "emilylange/*";
      DRONE_LIMIT_TRUSTED = "true";
      DRONE_RPC_HOST = "drone.geklaute.cloud";
      DRONE_RPC_PROTO = "https";
      DRONE_RUNNER_CAPACITY = "1";

      ## place `XDG_CACHE_HOME` in `CacheDirectory=` so
      ## we can persist nix' eval cache
      DRONE_RUNNER_ENVIRON = "XDG_CACHE_HOME:%C/drone-runner-exec/cache";
    };

    ## no idea why, but git has to come from unstable.
    ## at least if one wants to have working
    ## git clones from private repos.
    ## might be some change in nixpkgs between stable and unstable
    ## or something between the corresponding git version /shrug
    path = with pkgs; [
      bash
      git
      nix
      curl
    ];

    serviceConfig = {
      CacheDirectory = "drone-runner-exec";
      StateDirectory = "drone-runner-exec";
      ExecStart = lib.getExe (pkgs.drone-runner-exec);
      EnvironmentFile = config.deployment.keys."drone_rpc_secret_env".path;
      User = "drone-runner-exec";
      DynamicUser = true;

      # nix store/daemon for building
      # (the sole purpose of this runner)
      BindPaths = [ "/nix/var/nix/daemon-socket/socket" ];
      BindReadOnlyPaths = [ "/nix/" ];

      ## Hardening
      LockPersonality = true;
      PrivateDevices = true;
      PrivateTmp = true;
      PrivateUsers = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectSystem = "strict";
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
    };
  };

  deployment.keys."drone_rpc_secret_env" = {
    destDir = "/";
    ## `DRONE_RPC_SECRET=<secret>`
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/drone_rpc_secret_env" ];
  };

  ## enable cross compilation for aarch64
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nix.gc.automatic = lib.mkForce false;
}
