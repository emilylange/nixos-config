{ pkgs, lib, ... }:

{
  programs.vscode = {
    enable = true;

    ## Use vscode-fhs because extensions like Live Share somewhat require fhs
    ## and patching all of them is error prone, slow and painful.
    ## See https://github.com/NixOS/nixpkgs/blob/961ca7877e56703b625c6392e1e8fd7a4de7ff7c/pkgs/applications/editors/vscode/generic.nix#L133-L141
    ## and https://github.com/NixOS/nixpkgs/pull/99968
    ## Note: buildFHSUserEnvBubblewrap does not work with aarch64 yet.

    ## `vscode-fhsWithPackages` is an helper function for `vscode-fhs`,
    ## which allows one to make additional packages available in the buildFHSUserEnvBubblewrap
    ## and thus for vscode itself and its extensions
    package = pkgs.vscode-fhsWithPackages (
      additionalPkgs: with additionalPkgs; [
        ## dotnet3 and thus live share (vsls), has problems with `icu >= 71` currently.
        ## so until the dotnet3/vsls upstream fixes that, we need to pin the version to `< 71` :(
        ## TODO: Remove explicit `icu` version pin again
        icu70

        ## ext `redhat.ansible` requires python to be installed
        python3

        ## go
        delve
        go-tools
        gopls
      ]
    );

    userSettings = {
      "[nix]"."editor.formatOnSave" = true;
      "diffEditor.ignoreTrimWhitespace" = false;
      "editor.fontFamily" = "MesloLGS NF";
      "extensions.ignoreRecommendations" = true;
      "files.insertFinalNewline" = true;
      "files.trimTrailingWhitespace" = true;
      "telemetry.telemetryLevel" = "off";
      "terminal.integrated.persistentSessionReviveProcess" = "never";
      "update.mode" = "none";
      "workbench.colorTheme" = "One Dark Pro";
      "workbench.sideBar.location" = "right";
      "workbench.startupEditor" = "none";

      nix = {
        enableLanguageServer = true;
        serverPath = lib.getExe pkgs.nil;
        serverSettings = {
          nil.formatting.command = [ (lib.getExe pkgs.nixpkgs-fmt) ];
        };
      };
    };

    extensions = with pkgs.vscode-extensions; [
      jnoortheen.nix-ide
      valentjn.vscode-ltex
    ];
  };
}
