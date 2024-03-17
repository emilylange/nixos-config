{ pkgs, config, ... }:

{
  hardware.opengl.enable = true;
  security.polkit.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  ## auto-login for user "me" on tty1.
  ## assumes sway to be enabled and configured in home-manager.
  services.greetd = {
    enable = true;
    restart = false;
    settings = {
      initial_session = {
        command = "sway";
        user = "me";
      };
      default_session.command = "${config.services.greetd.package}/bin/agreety --cmd sway";
    };
  };

  security.pam.services.waylock = { };

  ## React immediatly to lid events after resume, instead of waiting some arbitrary 30s,
  ## in order to allow quick re-suspend-ing by closing the lid again.
  services.logind.extraConfig = ''
    HoldoffTimeoutSec=0
  '';
}
