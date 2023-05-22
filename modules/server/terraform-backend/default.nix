{ pkgs, config, lib, ... }:

with lib;

let
  cfg = config.services.terraform-backend;
  user = "terraform-backend";
  group = "terraform-backend";
in
{
  options.services.terraform-backend = {
    enable = mkEnableOption "terraform-backend state backend server";

    package = mkPackageOptionMD pkgs "terraform-backend" { };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/terraform-backend";
      description = ''
        Directory to be used as data and working directory.
        Useful when using `STORAGE_BACKEND = "fs"` with `STORAGE_FS_DIR = "./states"`.
      '';
    };

    extraEnvironment = mkOption {
      type = types.attrsOf types.str;
      description = "Additional environment variables passed to service.";
      default = { };
      example = { AUTH_BASIC_ENABLED = "true"; };
    };

    environmentFile = mkOption {
      type = with types; nullOr path;
      default = null;
      example = "/root/terraform-backend.env";
      description = ''
        Additional environment file as defined in {manpage}`systemd.exec(5)`.
        This allows passing env vars like {env}`REDIS_PASSWORD` and {env}`KMS_KEY`
        without adding them to the world-readable Nix store.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.terraform-backend = {
      description = "terraform-backend";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      environment = cfg.extraEnvironment;
      serviceConfig = {
        ExecStart = getExe cfg.package;
        EnvironmentFile = optional (cfg.environmentFile != null) cfg.environmentFile;
        WorkingDirectory = cfg.dataDir;
        User = user;
        Group = group;
      };
    };

    users.users.${user} = {
      isSystemUser = true;
      home = cfg.dataDir;
      group = group;
    };
    users.groups.${group} = { };
  };

  meta.maintainers = with maintainers; [ emilylange ];
}
