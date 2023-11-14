{ lib, ... }:

let
  listOfKeysToAttrs = keys: value: builtins.listToAttrs (map (key: lib.nameValuePair key value) keys);
in
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = listOfKeysToAttrs [
      "application/pdf"
      "image/*"
      "image/jpeg"
      "image/png"
      "image/svg+xml"
      "image/webp"
      "text/html"
      "text/xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ] "firefox.desktop";

    ## manually remove unwanted mimetypes (everything except `inode/directory`).
    ## see `cat $(nix-build "<nixpkgs>" -A kitty)/share/applications/kitty-open.desktop`
    associations.removed = listOfKeysToAttrs [
      "application/x-sh"
      "application/x-shellscript"
      "image/*"
      "text/*"
      "x-scheme-handler/kitty"
      "x-scheme-handler/ssh"
    ] "kitty-open.desktop";
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    extraConfig = {
      XDG_DEV_DIR = "$HOME/dev";
      XDG_MISC_DIR = "$HOME/Misc";
    };
  };
}
