{ lib, config, ... }:

with lib;

let
  globalConf = config;
in
{
  imports = [
    ./providers/borg.nix
    ./providers/restic.nix
  ];

  options.backups = mkOption {
    description = "abstraction over multiple backups providers";
    default = { };
    type = with types; attrsOf (submodule (
      { config, name, ... }: {
        options = {
          hostType = mkOption {
            type = types.enum [ "desktop" "server" ];
            description = ''
              Whether the host falls under the desktop or server category.
              This changes defaults for things like paths and bandwidth limits.
            '';
          };

          exclude = mkOption {
            type = with types; listOf str;
            default = {
              desktop = [
                "*/node_modules"
              ];
              server = [ ];
            }.${config.hostType};
            defaultText = literalExpression ''
              {
                desktop = [
                  "*/node_modules"
                ];
                server = [ ];
              }.''${config.backups.${name}.hostType};
            '';
            description = ''
              Paths to exclude.
              `~` will get replaced with every `isNormalUser`'s home.
            '';
          };

          paths = mkOption {
            type = with types; listOf str;
            default = {
              desktop = [
                "~/.gnupg"
                "~/.minecraft"
                "~/.mozilla"
                "~/.zsh_history"
                "~/Desktop"
                "~/dev"
                "~/Documents"
                "~/Misc"
                "~/Pictures"
                "~/Videos"
              ];
              server = (
                [ "/root" "/var/lib" ]
                ## assumes default paths that might get overwritten by
                ## `virtualisation.docker.extraOptions = [ "--data-root" ]`
                ++ lib.optional globalConf.virtualisation.docker.enable "/var/lib/docker/volumes"
                ++ lib.optional globalConf.virtualisation.podman.enable "/var/lib/containers/storage/volumes/"
              );
            }.${config.hostType};
            defaultText = literalExpression ''
              {
                desktop = [
                  "~/.gnupg"
                  "~/.minecraft"
                  "~/.mozilla"
                  "~/.zsh_history"
                  "~/Desktop"
                  "~/dev"
                  "~/Documents"
                  "~/Misc"
                  "~/Pictures"
                  "~/Videos"
                ];
                server = (
                  [ "/root" ]
                  ## assumes default paths that might get overwritten by
                  ## `virtualisation.docker.extraOptions = [ "--data-root" ]`
                  ++ lib.optional globalConf.virtualisation.docker.enable "/var/lib/docker/volumes"
                  ++ lib.optional globalConf.virtualisation.podman.enable "/var/lib/containers/storage/volumes/"
                );
              }.''${config.backups.${name}.hostType};
            '';
            description = ''
              Paths to backup.
              `~` will get replaced with every `isNormalUser`'s home.

              Note: borg hard-fails if it encouters a directory that does not exist.
            '';
          };

          extraPaths = mkOption {
            type = with types; listOf str;
            default = [ ];
            description = ''
              Extra paths appended to paths to backup.
              `~` will get replaced with every `isNormalUser`'s home.

              Note: borg hard-fails if it encouters a directory that does not exist.
            '';
          };

          timerOnCalendar = mkOption {
            type = types.str;
            description = "{manpage}`systemd.time(7)`";
            default = "daily";
          };
        };
      }
    ));
  };
}
