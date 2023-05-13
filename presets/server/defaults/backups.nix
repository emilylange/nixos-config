{ name, lib, ... }:

let
  backupName = "all";
  secrets = {
    borg = {
      passwordFile = secretAttrs "borg" "password" "password";
      sshKey = secretAttrs "borg" "notes" "sshKey";
    };
    restic = {
      passwordFile = secretAttrs "restic" "password" "password";
      sshKey = secretAttrs "restic" "notes" "sshKey";
    };
  };

  secretAttrs = provider: bitwardenType: secretType: rec {
    filename = "/backups_${backupName}_${provider}_${secretType}";
    keyCommand = [ "bw" "--nointeraction" "get" bitwardenType "gkcl/${name}/backups/${provider}/${secretType}" ];
    destDir = builtins.dirOf filename;
    keyName = builtins.baseNameOf filename;
  };
in
{
  backups.${backupName} = let filename = builtins.mapAttrs (_: v: v.filename); in
    {
      hostType = "server";
      timerOnCalendar = "00/2:15"; ## uses RandomizedDelaySec
      providers.borg.secrets = filename secrets.borg;
      providers.restic.secrets = filename secrets.restic;
    };

  deployment.keys = lib.concatMapAttrs
    (
      _: provider:
        lib.mapAttrs'
          (_: entry:
            lib.nameValuePair
              entry.keyName
              (
                { inherit (entry) destDir keyCommand; }
              )
          )
          provider
    )
    secrets;
}
