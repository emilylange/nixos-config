{ pkgs, ... }:

{
  services.xserver = {
    enable = true;

    desktopManager = {
      xterm.enable = false;
      xfce = {
        enable = true;
        noDesktop = true;
        enableXfwm = false;
      };
    };

    displayManager = {
      defaultSession = "xfce+i3";
      autoLogin = {
        enable = true;
        user = "me";
      };
    };

    windowManager.i3 = {
      enable = true;
      package = pkgs.i3-gaps;
      extraSessionCommands =
        let
          backgroundImage = builtins.fetchurl {
            ## https://www.reddit.com/r/unixporn/comments/uqbky7/aqua_monochrome/
            sha256 = "1pgcklrnax5nb59faclpd59ya3xj4nfry8ci17kkrsahnbmknag8";
            url = "https://github.com/Haruno19/dotfiles/raw/0ec5fb68067d52bd5ec9b4f6139524104015af42/Wallpapers/h9xl47mbld851.png";
          };
        in
        ''
          ${pkgs.feh}/bin/feh --bg-fill --no-fehbg ${backgroundImage}

          ## snixembed - proxy StatusNotifierItems as XEmbedded systemtray-spec icons
          ${pkgs.snixembed}/bin/snixembed &
        '';
    };

    ## x11 keymap
    layout = "de";
    xkbVariant = "nodeadkeys";
  };

  ## polkit
  environment.pathsToLink = [ "/libexec" ];
  environment.systemPackages = with pkgs; [
    polkit_gnome
  ];

  ## enable gnome-keyring for vscode and such
  services.gnome.gnome-keyring.enable = true;


  ## hdmi/dp backlight for ddcutil/ddcui
  hardware.i2c.enable = true;
}
