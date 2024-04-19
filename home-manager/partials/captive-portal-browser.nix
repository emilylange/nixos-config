{ pkgs, lib, ... }:

let
  networkmanager-get-dhcp4-nameserver = pkgs.writeShellApplication {
    name = "captive-portal-get-nameserver.sh";
    ## instead of dbus, something like `nmcli --get-values IP4.DNS device show` should work just as well lmao
    runtimeInputs = with pkgs; [ systemd jq ];
    text = ''
      nm_primary_connection="$(busctl get-property org.freedesktop.NetworkManager /org/freedesktop/NetworkManager org.freedesktop.NetworkManager PrimaryConnection --json=short | jq -r .data)"
      nm_dhcp_config="$(busctl get-property org.freedesktop.NetworkManager "$nm_primary_connection" org.freedesktop.NetworkManager.Connection.Active Dhcp4Config --json=short | jq -r .data)"
      busctl get-property org.freedesktop.NetworkManager "$nm_dhcp_config" org.freedesktop.NetworkManager.DHCP4Config Options --json=short | jq -r '.data.domain_name_servers.data | split(" ") | first'
    '';
  };
  firefox-profile-prefs-js = pkgs.writeTextFile {
    name = "prefs.js";
    text = ''
      user_pref("network.proxy.socks_port", 1666);
      user_pref("network.proxy.socks_remote_dns", true);
      user_pref("network.proxy.socks", "localhost");
      user_pref("network.proxy.type", 1);
      user_pref("dom.security.https_only_mode", false);

      user_pref("browser.safebrowsing.downloads.enabled", false);
      user_pref("browser.safebrowsing.malware.enabled", false);
      user_pref("browser.safebrowsing.phishing.enabled", false);

      # A bunch of other prefs that try to limit some annoyances when
      # Firefox is used with one-time profiles in private windows.
      # Notably a tab that opens its privacy policy and notification
      # bars for internet access and telemetry settings.
      user_pref("datareporting.policy.dataSubmissionEnabled", false);
      user_pref("network.captive-portal-service.enabled", false);
      user_pref("network.connectivity-service.enabled", false);
      user_pref("privacy.trackingprotection.enabled", false);
      user_pref("toolkit.telemetry.enabled", false);
      user_pref("toolkit.telemetry.reportingpolicy.firstRun", false);
    '';
  };

  firefox-captive-browser-onetime-profile = pkgs.writeShellApplication {
    name = "firefox-captive-browser-onetime-profile.sh";
    text = ''
      firefox_profile=$(mktemp -d --suffix .captive-portal-browser)
      cp --no-preserve=all ${firefox-profile-prefs-js} "$firefox_profile/prefs.js"
      firefox --no-remote --profile "$firefox_profile" --private-window "http://ip.gkcl.de"
    '';
  };
  toml = pkgs.formats.toml { };
in
{
  home.packages = with pkgs; [
    captive-browser
  ];

  xdg.configFile."captive-browser.toml" = {
    source = toml.generate "captive-browser.toml" {
      browser = lib.getExe firefox-captive-browser-onetime-profile;
      dhcp-dns = lib.getExe networkmanager-get-dhcp4-nameserver;
      socks5-addr = "localhost:1666";
    };
  };
}
