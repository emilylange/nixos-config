{ config, lib, pkgs, ... }:

{
  wayland.windowManager.sway = {
    enable = true;
    systemd.enable = true;
    config = {
      gaps = {
        inner = 10;
        outer = 0;
        smartGaps = true;
      };

      window.hideEdgeBorders = "smart";

      startup = [
        { command = "thunar --daemon"; }
      ];

      bars = [{
        statusCommand = "i3status-rs ~/.config/i3status-rust/config-default.toml";
        position = "top";
        fonts = {
          names = [ "MesloLGS NF" ];
          style = "Regular";
          size = 9.0;
        };
        colors = with config.colors; {
          background = black;
          inactiveWorkspace = {
            background = black;
            border = black;
            text = gray;
          };
          focusedWorkspace = {
            background = black;
            border = black;
            text = white;
          };
          activeWorkspace = {
            background = black;
            border = black;
            text = white;
          };
          urgentWorkspace = {
            background = black;
            border = black;
            text = pink;
          };
        };
      }];

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
          { app_id = "firefox"; }
        ];
        "3" = [
          { app_id = "thunar"; }
        ];
        "8" = [
          { app_id = "Element"; }
        ];
        "9" = [
          { class = "org.telegram.desktop"; }
        ];
        "10" = [
          ## TODO: figure out why vlc uses xwayland
          { class = "vlc"; }
        ];
      };


      modifier = "Mod1"; ## 'ALT'
      terminal = "kitty";
      menu = "rofi -show drun";

      ## floating windows
      floating.criteria = [
        { app_id = "org.gnome.Calculator"; }
        { title = "gotop terminal"; }
      ];

      keybindings =
        let
          modifier = config.wayland.windowManager.sway.config.modifier;
          windows = "Mod4"; ## (Windows/Super)
        in
        lib.mkOptionDefault {
          "${modifier}+p" = "exec kitty --title 'gotop terminal' gotop --color vice";
          "${windows}+e" = "exec thunar";
          "${windows}+z" = "exec ${lib.getExe pkgs.playerctl} play-pause";

          "${modifier}+Shift+f" = "exec rofi -show window";

          "${windows}+Shift+l" = "move container to output left";
          "${windows}+Shift+k" = "move workspace to output left";

          "XF86MonBrightnessDown" = "exec light -U 5";
          "XF86MonBrightnessUp" = "exec light -A 5";
        };

      output = {
        eDP-1 = {
          scale = "1.1";
        };

        "*".bg = toString [
          (builtins.fetchurl {
            ## https://www.reddit.com/r/unixporn/comments/uqbky7/aqua_monochrome/
            sha256 = "1pgcklrnax5nb59faclpd59ya3xj4nfry8ci17kkrsahnbmknag8";
            url = "https://github.com/Haruno19/dotfiles/raw/0ec5fb68067d52bd5ec9b4f6139524104015af42/Wallpapers/h9xl47mbld851.png";
          })
          "fill"
        ];
      };

      input."type:touchpad" = {
        dwt = "enabled";
        tap = "enabled";
        natural_scroll = "disabled";
        middle_emulation = "enabled";
      };

      input."type:keyboard" = {
        xkb_layout = "de";
        xkb_variant = "nodeadkeys";
      };
    };
  };

  programs.i3status-rust = {
    enable = true;
    bars = {
      default = {
        settings = {
          theme.overrides = with config.colors; {
            alternating_tint_bg = black;
            alternating_tint_fg = white;
            critical_bg = black;
            critical_fg = white;
            good_bg = black;
            good_fg = white;
            idle_bg = black;
            idle_fg = white;
            info_bg = black;
            info_fg = white;
            separator_bg = black;
            separator_fg = gray;
            warning_bg = black;
            warning_fg = white;

            separator = "/";
            end_separator = "";
          };
        };

        blocks = [
          {
            block = "music";
            format = "   $combo   |";
            separator = "·";
          }
          {
            block = "net";
            format = "   $speed_down.eng(prefix_space:true, width:1) ~ $speed_up.eng(prefix_space:true, width:1)   ";
          }
          {
            block = "cpu";
            format = "   $utilization.eng(prefix_space:true, width:1)   ";
            interval = 3;
          }
          {
            block = "memory";
            format = "   $mem_used.eng(prefix_space:true, width:1)   ";
            interval = 3;
          }
          {
            block = "disk_space";
            format = "   $free.eng(prefix_space:true, width:1)   ";
            interval = 60;
            path = "/";
          }
          {
            block = "battery";
            driver = "upower";
            format = "   $percentage.eng(prefix_space:true, width:1)   ";
            charging_format = "   [+] $percentage.eng(prefix_space:true, width:1)   ";
            empty_format = "   [!] $percentage.eng(prefix_space:true, width:1)   ";
            missing_format = "";
          }
          {
            block = "time";
            format = "   $timestamp.datetime(f:'%a, %H:%M:%S')   ";
            interval = 1;
          }
        ];
      };
    };
  };
}