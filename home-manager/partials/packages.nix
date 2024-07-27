{ pkgs, ... }:

{
  home.packages = with pkgs; [
    android-tools
    ansible
    ansible-lint
    bitwarden-cli
    caddy
    colmena
    doggo
    farge
    gnome-calculator
    jq
    kubectl
    kubernetes-helm
    kustomize
    mumble
    networkmanagerapplet
    nix-output-monitor
    pavucontrol
    rclone
    remmina
    seahorse # gnome keyring gui
    telegram-desktop
    thunderbird
    trash-cli
    vlc
    xarchiver
    xcaddy
    xdg-utils
    xfce.xfce4-power-manager
    xfce.xfce4-taskmanager
    xfce.xfce4-terminal
    yq
  ];

  programs.go = {
    enable = true;
  };
}
