{ pkgs, ... }:

{
  home.packages = with pkgs; [
    android-tools
    ansible
    ansible-lint
    bitwarden
    bitwarden-cli
    caddy
    colmena
    dogdns ## has no IPv6 support :<
    farge
    firefox
    gnome.gnome-calculator
    gnome.seahorse ## gnome keyring gui
    jq
    kubectl
    kubernetes-helm
    kustomize
    networkmanagerapplet
    nix-output-monitor
    pavucontrol
    rclone
    remmina
    tdesktop
    thunderbird
    trash-cli
    ungoogled-chromium
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
