{ ... }:

{
  services.acme-dns = {
    enable = true;
    settings = {
      api = {
        ip = "127.0.0.4";
        disable_registration = false;
      };

      general = rec {
        domain = "acme-dns.geklaute.cloud";
        nsname = domain;
        nsadmin = "acme-dns.soa@geklaute.cloud";
        ## note: this A/AAAA/NS setup differs slightly from what upstream recommends,
        ## due to a limitation in Cloudflare (the domain's nameservers -- for now).
        ## if you intend on setting up acme-dns yourself, consider looking at the
        ## nixos module or upstream docs for the `records` option instead.
        records = [
          "${domain}. NS acme-dns-ns.geklaute.cloud."
        ];
        ## systemd-resolved already binds on ipv4
        protocol = "both6";
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
