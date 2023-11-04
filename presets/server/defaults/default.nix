{ lib, name, pkgs, modulesPath, ... }:

{
  imports = [
    ./backups.nix
    ./sshd.nix
    "${modulesPath}/profiles/minimal.nix"
  ];

  system.nixos.versionSuffix = "";

  isServer = true;

  environment.systemPackages = with pkgs; [
    tmux
  ];

  ## overwrite `noXlibs = true` set by `profiles/minimal.nix`,
  ## because some packages seem to fail to build otherwise.
  ## TODO: investigate potential savings in closure size
  ## TODO: investigate why certain packages fail to build
  environment.noXlibs = false;

  boot.enableContainers = true;

  networking.hostName = lib.mkDefault name;
}
