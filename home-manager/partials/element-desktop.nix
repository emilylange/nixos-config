{ pkgs, lib, redacted, ... }:

{
  home.packages = with pkgs; [
    element-desktop
  ];

  xdg.desktopEntries =
    let
      profiles = [
        "indeednotjames.com"
        "matrix.org"
      ] ++ redacted.hm.element-desktop.profiles;

      generateElementEntry = profileName:
        lib.nameValuePair "element-desktop-${profileName}" {
          name = "Element (${profileName})";
          genericName = "Matrix Client (${profileName})";
          exec = "element-desktop --profile=\"${profileName}\" %u";
          icon = "element";
        };
    in
    builtins.listToAttrs (
      builtins.map generateElementEntry profiles
    );
}
