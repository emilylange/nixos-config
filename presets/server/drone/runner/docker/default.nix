{ lib, config, pkgs, ... }:

{
  assertions = [{
    assertion = config.virtualisation.docker.enable;
    message = "drone-runner-docker requires docker";
  }];

  systemd.services.drone-runner-docker = {
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" ];

    path = with pkgs; [ tmate ];

    environment = {
      DRONE_RPC_HOST = "drone.geklaute.cloud";
      DRONE_RPC_PROTO = "https";
      DRONE_RUNNER_NETWORK_ENABLE_IPV6 = "true";
      DRONE_RUNNER_PRIVILEGED_IMAGES = lib.concatStringsSep "," [
        "plugins/docker"
      ];
      DRONE_TMATE_ENABLED = "true";
    };

    serviceConfig = {
      ExecStart = lib.getExe (pkgs.callPackage ../../../../../packages/drone-runner-docker { });
      EnvironmentFile = config.deployment.keys."drone_rpc_secret_env".path;
    };
  };

  deployment.keys."drone_rpc_secret_env" = {
    destDir = "/";
    ## `DRONE_RPC_SECRET=<secret>`
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/drone_rpc_secret_env" ];
  };
}
