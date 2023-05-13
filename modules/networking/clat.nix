{ config, lib, pkgs, ... }:

let
  cfg = config.networking.clat;
  clat = pkgs.callPackage ../../packages/clat {
    inherit (cfg)
      interface
      ipv6
      nat64
      ;
  };
in
{
  options.networking.clat = with lib; {
    enable = mkEnableOption "464XLAT CLAT Node-Based Edge Relay";

    ipv6 = mkOption {
      type = types.str;
      description = ''
        This CLAT module based on Jool requires its own IPv6 address,
        which must unique.
        Meaning, you cannot use an existing IPv6.
      '';
    };

    interface = mkOption {
      type = types.str;
      description = "The network interface name to use for {option}`networking.clat.ipv6`";
      default = "eth0";
    };

    nat64 = mkOption {
      type = types.str;
      description = "IPv6 subnet (in CIRD) of the NAT64 service.";
      example = "64:ff9b::/96";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.jool-clat = {
      serviceConfig = {
        ExecStart = "${clat}/bin/clat.sh start";
        ExecStopPost = "${clat}/bin/clat.sh stop";
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = 5;
        StartLimitIntervalSec = "5min";
        StartLimitBurst = 10;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" "modprobe@jool_siit.service" ];
    };

    boot = {
      extraModulePackages = with config.boot.kernelPackages; [ jool ];
      kernelModules = [ "jool_siit" ];
      kernel.sysctl = {
        "net.ipv6.conf.${cfg.interface}.proxy_ndp" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
      };
    };

    networking.firewall.checkReversePath = false;

    networking.firewall.extraCommands = ''
      ip6tables -I FORWARD -i to_jool -j ACCEPT
      ip6tables -I FORWARD -o to_jool -j ACCEPT
      ip46tables -t mangle -A FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
    '';
    networking.firewall.extraStopCommands = ''
      ip6tables -D FORWARD -i to_jool -j ACCEPT || true
      ip6tables -D FORWARD -o to_jool -j ACCEPT || true
      ip46tables -t mangle -D FORWARD -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu || true
    '';
  };
}
