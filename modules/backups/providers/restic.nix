{ config, lib, options, ... }@args:

with lib;

let
  inherit (import ../helper.nix args) secretPath replaceHomePaths buildSshKnownHostAttr;
  cfg = config.backups;
  globalConf = config;
in
{
  options.backups = mkOption {
    type = with types; attrsOf (submodule ({ name, ... }: {
      options.providers.restic = mkOption {
        type = types.submodule {
          options = {
            sftpHost = mkOption {
              type = types.str;
              description = ''
                Remote sftp host to use as destination for backups.
              '';
              default = globalConf.redacted.global.backups.restic.sftpHost;
              defaultText = literalExpression "config.redacted.global.backups.restic.sftpHost";
              example = "user@sftp.example.com";
            };
            sshKnownHosts = mkOption {
              type = options.programs.ssh.knownHosts.type;
              default = globalConf.redacted.global.backups.restic.sshKnownHosts;
            };
            repository = mkOption {
              type = types.str;
              description = ''
                Base of repository url.
                The final repository url passed to restic will contain the {option}`backups.${name}` name.
                Should contain a trailing `/`.
              '';
              default = "${globalConf.redacted.global.backups.restic.repoBase}${globalConf.networking.hostName}/${name}";
              defaultText = literalExpression ''''${config.redacted.global.backups.restic.repoBase}''${config.networking.hostName}/''${name}'';
              example = "sftp:user@sftp.example.com:/data/";
            };
            secrets = {
              passwordFile = mkOption {
                type = types.str;
                description = ''
                  File to read the encryption password from.
                  Passed as is to {option}`services.restic.backups.<name>.passwordFile`
                '';
                default = secretPath name "restic" "pw";
              };
              sshKey = mkOption {
                type = types.str;
                description = ''
                  Location of ssh key used when connecting.
                '';
                default = secretPath name "restic" "id_ed25519";
              };
            };
            raw = mkOption {
              type = types.attrsOf types.anything;
              description = ''
                Optional values that get merged into underlying
                {option}`services.restic.backups.${name}`
              '';
              default = { };
            };
          };
        };
        description = ''
          Reduced set of specific options for restic.
        '';
        default = { };
      };
    }));
  };

  config = mkIf (cfg != { }) {
    services.restic.backups = mapAttrs'
      (name: value: nameValuePair name (
        let specific = value.providers.restic; in
        {
          passwordFile = specific.secrets.passwordFile;
          initialize = true;
          rcloneOptions.bwlimit = lib.strings.optionalString (value.hostType == "desktop") "1M";
          repository = specific.repository;
          timerConfig = {
            OnCalendar = value.timerOnCalendar;
            RandomizedDelaySec = "1h";
            Persistent = true;
          };
          pruneOpts = [
            "--keep-within 1d"
            "--keep-daily 7"
            "--keep-weekly 4"
            "--keep-monthly 12"
          ];
          extraOptions = [
            "sftp.command='ssh ${specific.sftpHost} -i ${specific.secrets.sshKey} -s sftp'"
          ];
          paths = replaceHomePaths (value.paths ++ value.extraPaths);
          extraBackupArgs = map (e: "--exclude='${e}'") (replaceHomePaths value.exclude);
        } // specific.raw
      ))
      cfg;

    programs.ssh.knownHosts = buildSshKnownHostAttr "restic";
  };
}
