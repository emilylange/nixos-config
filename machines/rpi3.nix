## nixos-generate --format sd-aarch64-installer --configuration machines/rpi3.nix
{ modulesPath, config, ... }:

{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  networking.bonds.bond0 = {
    interfaces = [
      "eth0"
      "wlan0"
    ];
    driverOptions = {
      mode = "active-backup";
      primary = "eth0";
      miimon = "100";
    };
  };

  networking.interfaces.bond0.ipv4.addresses = [{
    address = "192.168.10.10";
    prefixLength = 24;
  }];

  networking.defaultGateway = {
    address = "192.168.10.1";
    interface = "bond0";
  };

  networking.wireless = {
    enable = true;
    environmentFile = config.deployment.keys."wpa_supplicant".path;
    scanOnLowSignal = false;

    networks = {
      example = {
        psk = "@EXAMPLE_PSK@";
        authProtocols = [
          "WPA-PSK-SHA256" ## mixed WPA2-PSK/WPA3-SAE
        ];
      };
    };
  };

  boot.extraModprobeConfig = ''
    options cfg80211 ieee80211_regdom="DE"
  '';

  deployment.keys."wpa_supplicant" = {
    destDir = "/root/keys";
    text = ''
      EXAMPLE_PSK=<pw>
    '';
  };

  ## hdmi output
  boot.initrd.kernelModules = [ "vc4" "bcm2835_dma" "i2c_bcm2835" ];

  nixpkgs.system = "aarch64-linux";
  system.stateVersion = "22.05";
}
