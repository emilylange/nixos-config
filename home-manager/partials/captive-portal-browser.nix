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
  toml = pkgs.formats.toml { };
in
{
  home.packages = with pkgs; [
    captive-browser
  ];

  xdg.configFile."captive-browser.toml" = {
    source = toml.generate "captive-browser.toml" {
      browser = ''
        chromium \
          --user-data-dir="$(mktemp -d --suffix .captive-portal-browser)/" \
          --proxy-server="socks5://$PROXY" \
          --host-resolver-rules="MAP * ~NOTFOUND , EXCLUDE localhost" \
          --no-first-run --new-window --incognito \
          http://ip.gkcl.de
      '';
      dhcp-dns = lib.getExe networkmanager-get-dhcp4-nameserver;
      socks5-addr = "localhost:1666";
    };
  };
}
