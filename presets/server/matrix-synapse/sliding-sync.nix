{ ... }:

{
  services.matrix-synapse.sliding-sync = {
    enable = true;
    environmentFile = "/matrix-sliding-sync.env";
    settings = {
      SYNCV3_SERVER = "https://mx-synapse.indeednotjames.com";
      SYNCV3_BINDADDR = "[::]:8009";
      SYNCV3_LOG_LEVEL = "error";
    };
  };

  networking.firewall.interfaces.internal.allowedTCPPorts = [ 8009 ];
}
