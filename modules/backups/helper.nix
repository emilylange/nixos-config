{ lib, config, ... }:

let
  normalUsers = lib.filterAttrs (k: v: v.isNormalUser) config.users.users;
  userHomes = lib.mapAttrsToList (k: v: v.home) normalUsers;
in
{
  secretPath = job: provider: secret: "/backups/${job}/${provider}/${secret}";
  replaceHomePaths = paths: lib.concatMap
    (
      path:
      if (lib.strings.hasPrefix "~" path)
      then
        (
          map
            (userPath: userPath + lib.strings.removePrefix "~" path)
            userHomes
        )
      else
        [ path ]
    )
    paths;
  buildSshKnownHostAttr = provider: lib.concatMapAttrs
    (
      backupName: backupValue:
        lib.mapAttrs'
          (entryName: host:
            lib.nameValuePair
              "backups_${backupName}_${entryName}"
              host
          )
          backupValue.providers.${provider}.sshKnownHosts
    )
    config.backups;
}
