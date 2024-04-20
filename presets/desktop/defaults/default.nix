{ config, ... }:

{
  imports = [
    ../../common/docker
    ./fonts.nix
    ./home-manager.nix
    ./languagetool-server.nix
    ./packages.nix
    ./pipewire.nix
    ./scanner.nix
    ./users.nix
    ./wayland.nix
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

  ## yubikey
  services.pcscd.enable = true;

  ## display backlight
  programs.light.enable = true;

  ## battery
  services.upower.enable = true;

  services.gnome.gnome-keyring.enable = true;

  services.earlyoom.enable = true;

  ## enable Ozone (enables wayland for chromium/electron)
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  ## enable cross compilation for aarch64
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  nixpkgs.config.allowUnfree = true;
}
