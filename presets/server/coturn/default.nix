{ config, ... }:

{
  services.coturn = {
    enable = true;
    realm = "turn.geklaute.cloud"; ## custom IPv4-only dns record, because I read somewhere that VoIPv6 is somewhat misbehaving in Element (?)
    no-tls = true;
    no-dtls = true;
    no-cli = true;

    ## "VoIP traffic is all UDP"
    ## https://matrix-org.github.io/synapse/develop/turn-howto.html
    no-tcp-relay = true;

    use-auth-secret = true;
    static-auth-secret-file = "/coturn_static-auth-secret";

    extraConfig = ''
      denied-peer-ip=10.0.0.0-10.255.255.255
      denied-peer-ip=192.168.0.0-192.168.255.255
      denied-peer-ip=172.16.0.0-172.31.255.255

      no-multicast-peers
      denied-peer-ip=0.0.0.0-0.255.255.255
      denied-peer-ip=100.64.0.0-100.127.255.255
      denied-peer-ip=127.0.0.0-127.255.255.255
      denied-peer-ip=169.254.0.0-169.254.255.255
      denied-peer-ip=192.0.0.0-192.0.0.255
      denied-peer-ip=192.0.2.0-192.0.2.255
      denied-peer-ip=192.88.99.0-192.88.99.255
      denied-peer-ip=198.18.0.0-198.19.255.255
      denied-peer-ip=198.51.100.0-198.51.100.255
      denied-peer-ip=203.0.113.0-203.0.113.255
      denied-peer-ip=240.0.0.0-255.255.255.255

      verbose
    '';
  };

  deployment.keys."coturn_static-auth-secret" = {
    destDir = "/";
    permissions = "0400";
    keyCommand = [ "bw" "--nointeraction" "get" "password" "gkcl/coturn_static-auth-secret" ];
    user = config.systemd.services.coturn.serviceConfig.User;
  };

  networking.firewall = {
    allowedTCPPorts = [ 3478 ];
    allowedUDPPorts = [ 3478 ];
    allowedUDPPortRanges = with config.services.coturn; [
      { from = min-port; to = max-port; }
    ];
  };

}
