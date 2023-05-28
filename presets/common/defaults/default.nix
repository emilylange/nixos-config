{ pkgs, redacted, ... }:

{
  imports = [
    ./nix.nix
  ];

  config = {
    networking.nameservers = [
      "2a0f:fc80::"
      "2a0f:fc81::"
      "193.110.81.0"
    ];

    ## enable dns resolution for podman networks, specified here,
    ## because `virtualisation.oci-containers` defaults to podman
    ## and I don't want to import some podman specific file each
    ## time I might use oci-containers *somewhere*
    virtualisation.containers.containersConf.cniPlugins = with pkgs; [
      cni-plugins
      dnsname-cni
    ];

    environment.systemPackages = with pkgs; [
      bandwhich
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

    environment.sessionVariables.EDITOR = "vim";

    boot.loader = {
      timeout = 1;
      systemd-boot.consoleMode = "max";
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
