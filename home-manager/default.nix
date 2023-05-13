{ osConfig, ... }:

{
  imports = [
    ./partials/element-desktop.nix
    ./partials/firefox.nix
    ./partials/fish.nix
    ./partials/git.nix
    ./partials/gnupg.nix
    ./partials/gtk-settings.nix
    ./partials/i3wm.nix
    ./partials/kitty.nix
    ./partials/packages.nix
    ./partials/polybar.nix
    ./partials/rofi.nix
    ./partials/ssh.nix
    ./partials/vscode.nix
    ./partials/xdg.nix
    ./vars.nix ## `config.colors`
  ];

  home.stateVersion = osConfig.system.stateVersion;
}
