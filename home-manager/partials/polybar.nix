{ pkgs, config, ... }:

let
  colors = config.colors;
  playerctlCmd = "${pkgs.playerctl}/bin/playerctl";
  modulePadding = "15pt";
in
{
  services.polybar = {
    enable = true;
    package = pkgs.polybar.override {
      i3Support = true;
    };

    settings = {
      settings = {
        format-underline = colors.gray;
        format-padding = modulePadding;
      };

      "bar/base" = {
        monitor = "\${env:MONITOR}";
        monitor-strict = true;

        foreground = colors.white;
        background = colors.black;

        width = "100%";
        height = 25;
        bottom = false;
        fixed-center = true;

        ## Under-/overline pixel size
        line-size = 2;

        separator = "/";
        separator-foreground = colors.gray;
        separator-underline = colors.gray;

        padding = 0;

        font = [
          "MesloLGS NF:style=Regular:size=9;3"
          "MesloLGS NF:style=Regular:size=13;3"
        ];

        modules-left = "i3";
        modules-center = "playerctl";
        modules-right = "network-wireless network-wired cpu memory fs battery date";
      };

      "bar/main" = {
        "inherit" = "bar/base";

        tray-position = "right";
        tray-padding = -2;
      };

      "bar/secondary" = {
        "inherit" = "bar/base";
      };

      "module/cpu" = {
        type = "internal/cpu";

        interval = 3;
        label = "%percentage% %";
      };

      "module/date" = {
        type = "internal/date";

        interval = 1;
        date = "%a";
        date-alt = "%a %F";
        time = "%T";
        time-alt = "%T";
        label = "%date%, %time%";
      };

      "module/i3" = {
        type = "internal/i3";
        pin-workspaces = true;
        strip-wsnumbers = true;
        enable-scroll = true;

        ws-icon = [
          "1;"
          "2;"
          "3;"
          "4;"
          "5;"
          "6;"
          "7;"
          "8;"
          "9;"
          "10;"
        ];
        ws-icon-default = "";

        format-padding = 0;

        label-unfocused = "%icon%";
        label-unfocused-font = 2;
        label-unfocused-padding = modulePadding;
        label-unfocused-foreground = colors.gray;

        label-focused = "%icon%";
        label-focused-font = 2;
        label-focused-padding = modulePadding;
        label-focused-underline = colors.white;

        label-urgent = "%icon%";
        label-urgent-font = 2;
        label-urgent-padding = modulePadding;
        label-urgent-underline = colors.pink;

        label-visible = "%icon%";
        label-visible-font = 2;
        label-visible-padding = modulePadding;
        label-visible-underline = colors.white;
      };

      "module/fs" = {
        type = "internal/fs";
        mount = [
          "/"
        ];

        label-mounted = "%free%";
      };

      "module/network-wireless" = {
        type = "internal/network";
        interface-type = "wireless";

        speed-unit = "B/s";

        format-connected = "<label-connected>";
        label-connected = "%downspeed% ~ %upspeed%";
      };

      "module/network-wired" = {
        "inherit" = "module/network-wireless";
        interface-type = "wired";
      };

      "module/memory" = {
        type = "internal/memory";

        interval = 3;
        label = "%gb_used%";
        format = "<label>";
      };

      "module/playerctl" = {
        type = "custom/script";

        tail = true;
        exec = "${playerctlCmd} metadata --no-messages --follow --format \"{{ status }}: {{ title }} · {{ artist }}\" 2>/dev/null";
        scroll-up = "${playerctlCmd} next";
        double-click-left = "${playerctlCmd} next";
        scroll-down = "${playerctlCmd} previous";
        click-left = "${playerctlCmd} play-pause";
        click-middle = "${playerctlCmd} stop";
      };

      "module/battery" = {
        type = "internal/battery";

        ## TODO: Fetch `ls -1 /sys/class/power_supply/` automatically
        adapter = "ACAD";
        battery = "BAT1";

        label-charging = "[+] %percentage% %";
        label-discharging = "%percentage% %";
        label-full = "%percentage_raw% %";

        poll-interval = 60;
      };

    };
    script = builtins.readFile ../files/_/polybar.sh;
  };
}
