{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    adapta-gtk-theme
    btrfs-progs

    rar
    zip
    unzip
    p7zip

    ## icon theme
    numix-icon-theme-circle
  ];

  ## enable ratbadg for piper (logitech mouse)
  services.ratbagd.enable = true;

  ## requires an up-to-date nixpkgs channel set up for user root,
  ## which I don't want to do rn, because I use flakes instead :eyes:
  programs.command-not-found.enable = false;

  ## disable x11-ssh-askpass prompt
  programs.ssh = {
    enableAskPassword = false;
  };

  programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      thunar-archive-plugin
      thunar-media-tags-plugin
    ];
  };

  networking.networkmanager = {
    enable = true;
    dns = "none"; ## do not overwrite /etc/resolv.conf

    ## randomize mac addresses on each connect (and scan) by default
    ethernet.macAddress = "random";
    wifi.macAddress = "random";
    wifi.scanRandMacAddress = true;
  };
}
