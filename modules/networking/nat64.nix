{ lib
, config
, pkgs
, ...
}:

with lib;

let
  cfg = config.networking.nat64;
in
{
  options.networking.nat64 = {
    enable = mkEnableOption "NAT64 based on Jool";

    subnet = mkOption {
      type = types.str;
      description = ''
        IPv6 subnet (as CIRD) to map IPv4 addresses onto.
        Should be `/96` in length.
      '';
      example = "64:ff9b::/96";
    };

    enableNdppd = mkOption {
      type = types.bool;
      description = ''
        Whether to enable {option}`services.ndppd`
        to respond with neighbor advertisements for the whole NAT64 prefix.
        Useful, when that prefix isn't statically routed.
      '';
      default = true;
    };

    ndppdInterfaceName = mkOption {
      type = types.str;
      description = ''
        The network interface name {option}`services.ndppd` should respond
        on when {option}`networking.nat64.enableNdppd` is enabled.
      '';
      default = "eth0";
    };

    allowlist = mkOption {
      type = with types; nullOr (listOf str);
      default = null;
      description = ''
        List of IPv6 addresses (`/128` if cird is omitted) that to allow using the NAT64.
        Packets of IPs not listed will be `-j DROP`ed.
        Special value `null` disables the allowlist, thus allowing any IP.
      '';
    };

  };
  config = lib.mkIf cfg.enable {
    boot = {
      extraModulePackages = with config.boot.kernelPackages; [ jool ];
      kernelModules = [ "jool" ];
    };

    environment.systemPackages = with pkgs; [ jool-cli ];

    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    services.ndppd = mkIf cfg.enableNdppd {
      enable = true;
      proxies.${cfg.ndppdInterfaceName} = {
        router = false;
        rules.nat64 = {
          network = cfg.subnet;
          method = "static";
        };
      };
    };

    systemd.services.jool = {
      serviceConfig = {
        ExecStart = "${pkgs.jool-cli}/bin/jool instance add default --netfilter --pool6 ${cfg.subnet}";
        ExecStop = "${pkgs.jool-cli}/bin/jool instance remove default";
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" "modprobe@jool.service" ];
    };

    networking.firewall.extraCommands = mkIf (cfg.allowlist != null) ''
      ## jool only hooks into the PREROUTING chain, so we use that chain as well
      ip6tables -t mangle -N NAT64ALLOW 2>/dev/null || true
      ip6tables -t mangle -F NAT64ALLOW
      ip6tables -t mangle -I PREROUTING -j NAT64ALLOW

      ${
        builtins.concatStringsSep
        "\n"
        (map (v: "ip6tables -t mangle -A NAT64ALLOW --source ${v} --destination ${cfg.subnet} -j ACCEPT") cfg.allowlist)
      }
      ip6tables -t mangle -A NAT64ALLOW --destination ${cfg.subnet} -j DROP
    '';

    networking.firewall.extraStopCommands = ''
      ip6tables -t mangle -D PREROUTING -j NAT64ALLOW || true
      ip6tables -t mangle -F NAT64ALLOW || true
      ip6tables -t mangle -X NAT64ALLOW || true
    '';
  };
}
