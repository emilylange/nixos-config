{ config, inputs, ... }:

{
  nix = {
    gc = {
      automatic = config.isServer;
      dates = "daily";
      options = "--delete-older-than 7d";
      persistent = true;
      randomizedDelaySec = "12h";
    };

    optimise.automatic = config.isServer;

    settings = {
      auto-optimise-store = false; ## enabling it can cause significant performance degradation on slow systems
      trusted-users = [ "@wheel" ];
    };

    ## not a huge fan of github:NixOS/flake-registry
    registry = {
      nixpkgs.flake = inputs.${if config.isServer then "nixpkgs-small" else "nixpkgs"};
      n.to = { id = "nixpkgs"; type = "indirect"; }; ## shortcut
    };

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      flake-registry = "/etc/nix/registry.json";
    };

    nixPath = [
      "nixpkgs=flake:nixpkgs"
    ];
  };
}
