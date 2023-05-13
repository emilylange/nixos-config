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
      options.providers.borg = mkOption {
        type = types.submodule {
          options = {
            sshKnownHosts = mkOption {
              type = options.programs.ssh.knownHosts.type;
              default = globalConf.redacted.global.backups.borg.sshKnownHosts;
            };
            repository = mkOption {
              type = types.str;
              description = ''
                Base of repository url.
                The final repository url passed to borgbackup will contain the {option}`backups.${name}` name.
                Should contain a trailing `/`.
              '';
              default = "${globalConf.redacted.global.backups.borg.repoBase}${globalConf.networking.hostName}/${name}";
              defaultText = literalExpression ''''${config.redacted.global.backups.borg.repoBase}''${config.networking.hostName}/''${name}'';
              example = "ssh://user@example.com/./borg/";
            };
            secrets = {
              passwordFile = mkOption {
                type = types.str;
                description = ''
                  File to read the encryption password from.
                '';
                default = secretPath name "borg" "pw";
              };
              sshKey = mkOption {
                type = types.str;
                description = ''
                  Location of ssh key used when connecting.
                '';
                default = secretPath name "borg" "id_ed25519";
              };
            };
            raw = mkOption {
              type = types.attrsOf types.anything;
              description = ''
                Optional values that get merged into underlying
                {option}`services.borgbackup.jobs.${name}`
              '';
              default = { };
            };
          };
        };
        description = ''
          Reduced set of specific options for borgbackup.
        '';
        default = { };
      };
    }));
  };

  config = mkIf (cfg != { }) {
    services.borgbackup.jobs = mapAttrs'
      (name: value: nameValuePair name (
        let specific = value.providers.borg; in
        {
          environment.BORG_RSH = "ssh -i ${specific.secrets.sshKey}";
          paths = replaceHomePaths (value.paths ++ value.extraPaths);
          compression = "auto,zstd,10";
          encryption = {
            mode = "repokey-blake2";
            passCommand = "cat ${specific.secrets.passwordFile}";
          };
          prune.keep = {
            within = "1d";
            daily = 7;
            weekly = 4;
            monthly = 12;
          };
          exclude = replaceHomePaths value.exclude;
          startAt = value.timerOnCalendar;
          repo = specific.repository;
          extraArgs = lib.strings.optionalString (value.hostType == "desktop") "--upload-ratelimit=1024"; ## 1 MiB/s
        } // specific.raw
      ))
      cfg;

    systemd.timers = mapAttrs' (name: value: nameValuePair "borgbackup-job-${name}" { timerConfig.RandomizedDelaySec = "1h"; }) cfg;

    programs.ssh.knownHosts = buildSshKnownHostAttr "borg";
  };
}
