{ pkgs, ... }:

{
  home.packages = with pkgs; [
    android-tools
    ansible
    ansible-lint
    bandwhich ## currently broken. upstream: https://github.com/imsnif/bandwhich/pull/265
    bat
    bitwarden
    bitwarden-cli
    brightnessctl
    caddy
    chromium
    colmena
    discord
    dogdns ## has no IPv6 support :<
    drone-cli
    firefox
    flameshot
    gh
    gnome.gnome-calculator
    gnome.seahorse ## gnome keyring gui
    jq
    kubectl
    kubernetes-helm
    kustomize
    lxappearance
    minecraft
    networkmanagerapplet
    nodejs
    pavucontrol
    piper
    rclone
    remmina
    syncthing
    tdesktop
    thunderbird
    trash-cli
    vlc
    xarchiver
    xcaddy
    xcolor
    xfce.xfce4-power-manager
    xfce.xfce4-terminal
    yarn
  ];

  programs.go = {
    enable = true;
  };

  programs.obs-studio = {
    enable = true;
  };
}
