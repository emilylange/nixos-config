{ config, inputs, ... }:

{
  nix = {
    gc = {
      automatic = true;
      dates = if config.isServer then "daily" else "monthly";
      options = "--delete-older-than 14d";
      persistent = true;
      randomizedDelaySec = "12h";
    };

    optimise.automatic = true;

    settings = {
      auto-optimise-store = false; ## enabling it can cause significant performance degradation on slow systems
      trusted-users = [ "@wheel" ];
    };

    ## not a huge fan of github:NixOS/flake-registry
    registry = {
      nixpkgs.flake = inputs.nixpkgs;
    };

    extraOptions = ''
      experimental-features = nix-command flakes
      flake-registry = /etc/nix/registry.json
    '';

    nixPath = [
      "nixpkgs=flake:nixpkgs"
    ];
  };
}
