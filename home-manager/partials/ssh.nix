{ lib, redacted, ... }:

with builtins;

let
  dir = ./ssh;
  lsDir = readDir dir;
  filenames = attrNames (lib.filterAttrs (n: v: v == "regular") lsDir);
  typeOfFiles = groupBy (s: (lib.last (lib.splitString "." s))) filenames;
  buildPath = file: dir + "/${file}";
  fileToNixStore = file: (toFile file (readFile (buildPath file)));
  importFile = file: import (buildPath file);
  unmanagedSshConfigFile = "~/.ssh/config_imperative_unmanaged";
in
{
  ## automatically imports any files in the ./ssh/*
  ## directory relative to this file here.
  ##  - files ending with *.nix will be merged into matchBlocks = {}
  ##  - files NOT ending with *.nix will be put into includes = []
  programs.ssh = {
    enable = true;
    serverAliveInterval = 25;

    includes = [ unmanagedSshConfigFile ]
      ++ redacted.hm.ssh.includes
      ++ lib.optionals
      (hasAttr "ssh" typeOfFiles)
      (map fileToNixStore typeOfFiles.ssh);

    matchBlocks = lib.mkMerge (
      redacted.hm.ssh.matchBlocks
      ++ lib.optionalAttrs (hasAttr "nix" typeOfFiles) (map importFile typeOfFiles.nix)
    );

    extraConfig = ''
      SetEnv TERM=xterm-256color
      User root
      IdentitiesOnly yes
    '';
  };

  ## init empty ${unmanagedSshConfigFile} if file does not exists
  home.activation.initEmptyUnmanagedSshConfigFile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    bash -c "$DRY_RUN_CMD if [ ! -f ${unmanagedSshConfigFile} ]; then $DRY_RUN_CMD touch ${unmanagedSshConfigFile}; fi"
  '';
}
