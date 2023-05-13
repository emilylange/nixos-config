## Should work in theory, but hasn't been tested yet, because cross-compiling is pretty time-consuming due
## to the lack of a public binary cache and somewhat slow `boot.binfmt.emulatedSystems`.
## Also, I don't really have a use-case for a Raspberry Pi 2 anyway :shrug:
## @misuzu:matrix.org (#nixos-on-arm:nixos.org) shared their armv7h binary cache (https://hydra.armv7l.xyz/
## and https://gitlab.com/misuzu/hydra-armv7l/-/blob/fb84be3bbe4dab59b0170c0292b25b6f6d921de6/release.nix#L6-15)
## but I haven't actually looked at that yet :eyes:
##
## nix-build '<nixpkgs/nixos>' -I nixpkgs=channel:nixos-22.05-small -A config.system.build.sdImage -I nixos-config=./machines/rpi2.nix
{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
  ];

  nixpkgs.config.allowUnsupportedSystem = true;
  nixpkgs.system = "armv7l-linux";
  system.stateVersion = "22.05";
}
