{ config, lib, pkgs, ... }:

let
  waylock = "${lib.getExe pkgs.waylock} -fork-on-lock -init-color 0x6c71c4";
in
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

        extraConfig = ''
          wrap_scroll yes
        '';
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
          { app_id = "org.telegram.desktop"; }
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

          pamixer = lib.getExe pkgs.pamixer;
          playerctl = lib.getExe pkgs.playerctl;
        in
        lib.mkOptionDefault {
          "${modifier}+p" = "exec kitty --title 'gotop terminal' gotop --color vice";
          "${windows}+e" = "exec thunar";

          "${modifier}+Shift+f" = "exec rofi -show window";

          "${windows}+Shift+l" = "move container to output left";
          "${windows}+Shift+k" = "move workspace to output left";

          XF86AudioPlay = "exec ${playerctl} play-pause";
          XF86AudioPrev = "exec ${playerctl} previous";
          XF86AudioNext = "exec ${playerctl} next";

          XF86AudioMute = "exec ${pamixer} --toggle-mute";
          XF86AudioLowerVolume = "exec ${pamixer} --decrease 5";
          XF86AudioRaiseVolume = "exec ${pamixer} --increase 5";

          XF86MonBrightnessDown = "exec light -U 5";
          XF86MonBrightnessUp = "exec light -A 5";

          "${windows}+l" = "exec ${waylock}";

          ## until https://github.com/nix-community/home-manager/pull/4636 is merged
          "${modifier}+0" = "workspace number 10";
          "${modifier}+Shift+0" = "move container to workspace number 10";
        };

      output = {
        eDP-1 = {
          scale = "1.1";
        };

        DP-3 = {
          mode = "1920x1080@144Hz";
          pos = "1920 0";
        };

        HDMI-A-1 = {
          mode = "1920x1080@72Hz";
          pos = "0 0";
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
            block = "net";
            format = "   down $speed_down.eng(prefix_space:true, width:1) ~ up $speed_up.eng(prefix_space:true, width:1)   ";
          }
          {
            block = "music";
            format = "   $play$combo.str(max_width:30)   |";
            separator = " · ";
            click = [
              {
                button = "left";
                action = "play_pause";
              }
              {
                button = "right";
                action = "next";
              }
              {
                button = "up";
                action = "next";
              }
              {
                button = "down";
                action = "prev";
              }
            ];
            icons_overrides = {
              music_play = "Paused: ";
              music_pause = "Playing: ";
            };
          }
          {
            block = "cpu";
            format = "  cpu $utilization.eng(prefix_space:true, width:1)   ";
            interval = 3;
          }
          {
            block = "memory";
            format = "   mem $mem_used.eng(prefix_space:true, width:1)   ";
            interval = 3;
          }
          {
            block = "disk_space";
            format = "   disk $free.eng(prefix_space:true, width:1)   ";
            interval = 60;
            path = "/";
          }
          {
            block = "battery";
            driver = "upower";
            format = "   bat $percentage.eng(prefix_space:true, width:1)   ";
            charging_format = "   [+] $percentage.eng(prefix_space:true, width:1)   ";
            empty_format = "   [!] $percentage.eng(prefix_space:true, width:1)   ";
            missing_format = "";
            device = "BAT1";
          }
          {
            block = "sound";
            driver = "pulseaudio";
            device_kind = "sink";
            format = "   vol {$volume.eng(prefix_space:true, width:1)|muted}   ";
          }
          {
            block = "time";
            format = "   $timestamp.datetime(f:'%H:%M:%S')   ";
            interval = 1;
          }
        ];
      };
    };
  };

  services.swayidle = let swaymsg = lib.getExe' config.wayland.windowManager.sway.package "swaymsg"; in {
    enable = true;
    events = [
      { event = "before-sleep"; command = waylock; }
    ];
    timeouts = [
      {
        timeout = 300;
        command = waylock;
      }
      {
        timeout = 600;
        command = "${swaymsg} 'output * power off'";
        resumeCommand = "${swaymsg} 'output * power on'";
      }
    ];
  };
}
