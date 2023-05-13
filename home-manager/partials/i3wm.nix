{ config, lib, pkgs, ... }:

{
  xsession.windowManager.i3 = {
    enable = true;
    config = {
      gaps = {
        inner = 10;
        outer = 0;
        smartGaps = true;
      };

      window = {
        hideEdgeBorders = "smart";
      };

      startup = [
        { command = "systemctl --user restart polybar"; always = true; notification = false; }
        { command = "xfce4-power-manager"; notification = false; }
        { command = "thunar --daemon"; notification = false; }
        { command = "nm-applet"; notification = false; }
      ];

      colors = with config.colors;
        let
          base = {
            background = black;
            indicator = white;
            text = white;
          };
        in
        {
          focused = base // {
            border = white;
            childBorder = white;
          };

          urgent = base // {
            border = pink;
            childBorder = pink;
          };

          unfocused = base // {
            border = gray;
            childBorder = gray;
          };

          focusedInactive = base // {
            border = gray;
            childBorder = gray;
          };
        };

      assigns = {
        "1" = [
          { class = "Firefox"; }
        ];
        "3" = [
          { class = "Thunar"; }
        ];
        "7" = [
          { class = "^Steam$"; }
        ];
        "8" = [
          { class = "Element"; }
        ];
        "9" = [
          { class = "TelegramDesktop"; }
        ];
        "10" = [
          { class = "vlc"; }
        ];
      };

      ## remove i3-bars completely (see polybar below)
      bars = [ ];

      terminal = "kitty";

      menu = "rofi -show drun";

      ## floating windows
      floating.criteria = [
        { class = "(?i)gnome-calculator"; }
        { title = "gotop terminal"; }
      ];

      keybindings =
        let
          modifier = config.xsession.windowManager.i3.config.modifier; ## defaults to 'ALT' (Mod1)
          windows = "Mod4"; ## (Windows/Super)
        in
        lib.mkOptionDefault {
          "${modifier}+p" = "exec kitty --title 'gotop terminal' gotop --color vice";
          "${windows}+e" = "exec thunar";
          "${windows}+z" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";

          "${modifier}+Shift+f" = "exec rofi -show window";

          "${windows}+Shift+l" = "move container to output left";
          "${windows}+Shift+k" = "move workspace to output left";

          ## Overwrite default exit behaviour because we use xfce as desktop manager
          ## See https://nixos.wiki/wiki/Xfce#Using_as_a_desktop_manager_and_not_a_window_manager
          "${modifier}+Shift+e" = "exec xfce4-session-logout";

          ## Override the on/off button to not shutdown immediately
          "XF86PowerOff" = "exec xfce4-session-logout";
        };
    };
  };
}
