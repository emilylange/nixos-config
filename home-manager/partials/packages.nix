{ pkgs, ... }:

{
  home.packages = with pkgs; [
    android-tools
    ansible
    ansible-lint
    bitwarden
    bitwarden-cli
    brightnessctl
    caddy
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
    networkmanagerapplet
    pavucontrol
    piper
    rclone
    remmina
    tdesktop
    thunderbird
    trash-cli
    ungoogled-chromium
    vlc
    xarchiver
    xcaddy
    xcolor
    xfce.xfce4-power-manager
    xfce.xfce4-terminal
  ];

  programs.go = {
    enable = true;
  };

  programs.obs-studio = {
    enable = true;
  };
}
