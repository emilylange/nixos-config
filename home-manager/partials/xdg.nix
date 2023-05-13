{ config, lib, ... }:

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

    ## pretty silly way to remove all unwanted associations :^)
    associations.removed = with builtins;
      let
        name = "kitty-open.desktop";
        rawFile = readFile (config.programs.kitty.package.out + "/share/applications/" + name);
        rawMimeTypes = head (elemAt (split "MimeType=(.*)\n" rawFile) 1);
        filteredMineTypes = filter (v: v != "" && v != "inode/directory") (lib.splitString ";" rawMimeTypes);
      in
      listOfKeysToAttrs filteredMineTypes name;
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
