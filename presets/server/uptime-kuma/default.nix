{ ... }:

{
  services.uptime-kuma = {
    enable = true;
    settings = {
      UPTIME_KUMA_HOST = "127.0.0.3";
      UPTIME_KUMA_PORT = "3001"; ## default
    };
  };
}
