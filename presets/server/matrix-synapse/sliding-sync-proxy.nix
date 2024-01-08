{ ... }:

{
  services.matrix-sliding-sync = {
    enable = true;
    environmentFile = "/matrix-sliding-sync.env";
    settings = {
      SYNCV3_SERVER = "https://mx-synapse.indeednotjames.com";
      SYNCV3_BINDADDR = "127.0.0.50:8008";
      SYNCV3_LOG_LEVEL = "error";
    };
  };
}
