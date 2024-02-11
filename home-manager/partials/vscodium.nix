{ pkgs, lib, osConfig, ... }:

{
  programs.vscode = {
    enable = true;

    package = pkgs.vscodium;

    userSettings = {
      telemetry = {
        telemetryLevel = "off";
        enableCrashReporter = false;
        enableTelemetry = false;
      };
      extensions.autoCheckUpdates = false;
      extensions.autoUpdate = false;
      extensions.ignoreRecommendations = true;
      redhat.telemetry.enabled = false;
      update.mode = "none";
      update.showReleaseNotes = false;
      workbench.enableExperiments = false;
      workbench.settings.enableNaturalLanguageSearch = false;

      files = {
        insertFinalNewline = true;
        trimTrailingWhitespace = true;

        associations = {
          "flake.lock" = "json";
        };
      };

      diffEditor.ignoreTrimWhitespace = false;

      "[nix]".editor.formatOnSave = true;

      workbench = {
        colorTheme = "One Dark Pro";
        sideBar.location = "right";
        startupEditor = "newUntitledFile";
      };

      terminal.integrated.persistentSessionReviveProcess = "never";

      editor = {
        fontFamily = "MesloLGS NF";
        renderWhitespace = "trailing";
      };

      ## seems to prevent crashes on startup under wayland
      ## see https://github.com/NixOS/nixpkgs/issues/237978
      window.titleBarStyle = "custom";

      nix = {
        enableLanguageServer = true;
        serverPath = lib.getExe pkgs.nil;
        serverSettings = {
          nil.formatting.command = [ (lib.getExe pkgs.nixpkgs-fmt) ];
        };
      };

      ltex = {
        language = "en-US"; # "auto" (and by proxy "en" instead of "en-US" does not provide spelling checks)
        additionalRules.motherTongue = "de-DE";
        languageToolHttpServerUri = "http://localhost:${toString osConfig.services.languagetool.port}/";
      };
    };

    mutableExtensionsDir = false;
    extensions = with pkgs.vscode-extensions; [
      eamodio.gitlens
      golang.go
      jnoortheen.nix-ide
      matthewpi.caddyfile-support
      ms-python.python
      redhat.vscode-yaml
      rust-lang.rust-analyzer
      seatonjiang.gitmoji-vscode
      tamasfe.even-better-toml
      valentjn.vscode-ltex
      zhuangtongfa.material-theme
    ];
  };

  ## additional packages needed for certain extensions
  home.packages = with pkgs; [
    ## golang.go
    delve
    go-tools
    gopls

    ## ms-python.python
    python3
  ];
}
