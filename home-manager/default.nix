{ osConfig, ... }:

{
  imports = [
    ./partials/element-desktop.nix
    ./partials/firefox.nix
    ./partials/fish.nix
    ./partials/git.nix
    ./partials/gnupg.nix
    ./partials/gtk-settings.nix
    ./partials/kitty.nix
    ./partials/packages.nix
    ./partials/rofi.nix
    ./partials/ssh.nix
    ./partials/sway.nix
    ./partials/vscode.nix
    ./partials/xdg.nix
    ./vars.nix ## `config.colors`
  ];

  home.stateVersion = osConfig.system.stateVersion;
}
