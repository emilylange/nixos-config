{ pkgs, ... }:

{
  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    grabKeyboardAndMouse = false;
    defaultCacheTtl = 600; ## seconds
    pinentryPackage = pkgs.pinentry-gnome3;
  };
}
