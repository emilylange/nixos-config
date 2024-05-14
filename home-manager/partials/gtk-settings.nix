{ pkgs, ... }:

{
  gtk = {
    enable = true;
    iconTheme.name = "Numix-Circle";
    theme.name = "Adapta-Eta";
    font = {
      name = "Noto Sans";
      size = 9;
    };
    gtk3.bookmarks = [
      "file:///home/Downloads"
      "file:///tmp/ /tmp"
      "file:///home/dev ~/dev"
    ];
  };

  home.pointerCursor = {
    package = pkgs.vanilla-dmz;
    name = "Vanilla-DMZ-AA"; ## dark variant
    size = 20;
    x11.enable = true;
  };
}
