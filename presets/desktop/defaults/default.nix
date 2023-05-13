{ config, ... }:

{
  imports = [
    ../../common/docker
    ./fonts.nix
    ./home-manager.nix
    ./packages.nix
    ./pipewire.nix
    ./scanner.nix
    ./users.nix
    ./xorg.nix
  ];

  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];

  ## do not wake up from sleep from mouse
  services.udev.extraRules = ''
    ## logitech wireless mouse adapter
    ACTION=="add", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c53f", ATTR{power/wakeup}="disabled"
  '';

  services.fwupd.enable = true;

  ## enable cross compilation for aarch64
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nixpkgs.config.allowUnfree = true;

  backups.home.hostType = "desktop";
}
