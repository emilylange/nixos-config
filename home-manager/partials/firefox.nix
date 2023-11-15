{ lib, osConfig, ... }:

{
  programs.firefox = {
    enable = true;
    profiles = {
      default = {
        settings = {
          "browser.aboutConfig.showWarning" = false;
          "browser.search.suggest.enabled" = false;
          "browser.startup.homepage" = "about:blank";
          "browser.toolbars.bookmarks.visibility" = "never";
          "network.protocol-handler.external.mailto" = false; ## hide 'Add "$x" as an application for mailto links?' bar
          "signon.firefoxRelay.feature" = "disabled";

          ## DNS over HTTPS (DoH)
          "network.trr.mode" = 2;
          "network.trr.uri" = "https://open.dns0.eu";
        } // lib.optionalAttrs (osConfig.networking.hostName == "ryzen") {
          ## enable high refresh rate for desktop
          "layout.frame_rate" = 144;
        };
      };
    };
  };
}
