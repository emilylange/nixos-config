{ lib, pkgs, redacted, config, ... }:

{
  imports = [
    ./nix.nix
  ];

  config = {
    networking.nameservers =
      if config.services.resolved.enable then [
        "2a07:e340::2#dns.mullvad.net"
        "194.242.2.2#dns.mullvad.net"
      ] else [
        "2a0f:fc80::ffff" # open.dns0.eu
        "2a0f:fc81::ffff" # open.dns0.eu
        "193.110.81.254" # open.dns0.eu
      ];

    services.resolved = {
      fallbackDns = config.networking.nameservers;
      extraConfig = "DNSOverTLS=yes";
    };

    ## enable dns resolution for podman networks, specified here,
    ## because `virtualisation.oci-containers` defaults to podman
    ## and I don't want to import some podman specific file each
    ## time I might use oci-containers *somewhere*
    virtualisation.containers.containersConf.cniPlugins = with pkgs; [
      cni-plugins
      dnsname-cni
    ];

    environment.systemPackages = with pkgs; [
      bat ## cat alternative
      curlHTTP3
      dnsutils ## dig
      git
      gnupg
      gotop ## htop alternative
      nmap
      tree
      vim
      wget
    ];

    programs = {
      bandwhich.enable = true;
    };

    environment.sessionVariables.EDITOR = "vim";

    boot.loader = {
      timeout = 1;
      systemd-boot.consoleMode = "max";

      grub.configurationLimit = lib.mkDefault 20;
      systemd-boot.configurationLimit = lib.mkDefault 20;
    };

    time.timeZone = "Europe/Berlin";

    console = {
      font = "Lat2-Terminus16";
      keyMap = "de-latin1";
      earlySetup = true;
    };

    networking.firewall.logRefusedConnections = true;

    redacted = redacted.kv;
  };
}
