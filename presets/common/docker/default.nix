{ pkgs, lib, ... }:

let
  ## Yes, I am aware `64:ff9b:1::/48` from rfc8215 has a different purpose
  cirdList = builtins.genList (x: "64:ff9b:1:${lib.strings.toLower (lib.toHexString (8192 + x))}::/64") 512;
in
{
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;

    daemon.settings = {
      registry-mirrors = [
        "https://registry.ipv6.docker.com"
      ];

      ## Note: docker's internal dns silently ignores any IPv6 nameservers
      ## in `/etc/resolv.conf` (`config.networking.nameservers`) or configured here
      ##
      ## "Issue: Docker in IPv6 only - network problem"
      ## https://github.com/moby/moby/issues/32675
      ##
      ## "Issue: Feature request: IPv6-enabled embedded DNS server" (partially)
      ## https://github.com/moby/moby/issues/41651)
      dns = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
      ];

      ipv6 = true;
      ip6tables = true;
      experimental = true;
      fixed-cidr-v6 = builtins.head cirdList;

      ## manually provide "a few" unique /64 networks,
      ## instead of a single (which would be more than enough),
      ## because Docker is currently unable to properly
      ## split IPv6 subnets into smaller prefixes.
      ##
      ## Oh and if would we go any smaller than /64, e.g. /96,
      ## then Docker would consume all available RAM :shrug:
      ##
      ## "Issue: splitNetwork and addIntToIP fails for IPv6 addresses on /64+ size pools"
      ## https://github.com/moby/moby/issues/42801
      ##
      ## "Issue: IPv6 address pool subnet smaller than /80 causes dockerd to consume all available RAM"
      ## https://github.com/moby/moby/issues/40275
      default-address-pools = [
        {
          base = "172.17.0.0/12";
          size = 24;
        }
      ] ++ map
        (x: {
          base = x;
          size = 64;
        })
        (lib.drop 1 cirdList);
    };
  };

  environment.systemPackages = with pkgs; [ docker-compose ];
}
