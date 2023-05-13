{ lib, ... }:

{
  ## multiple `nixpkgs.config.allowUnfreePredicate` functions don't merge
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "drone-runner-docker"
    "drone-runner-exec"
    "drone.io"
  ];
}
