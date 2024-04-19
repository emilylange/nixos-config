{ ... }:

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

          "browser.safebrowsing.downloads.enabled" = false;
          "browser.safebrowsing.malware.enabled" = false;
          "browser.safebrowsing.phishing.enabled" = false;

          ## DNS over HTTPS (DoH)
          ## https://wiki.mozilla.org/Trusted_Recursive_Resolver
          "network.trr.mode" = 3;
          "network.trr.uri" = "https://dns.mullvad.net/dns-query";
        };
      };
    };
  };
}
