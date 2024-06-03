{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    lix.url = "https://git.lix.systems/lix-project/lix/archive/main.tar.gz";
    lix.flake = false;
    lix-module.url = "https://git.lix.systems/lix-project/nixos-module/archive/main.tar.gz";
    lix-module.flake = false;

    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    lanzaboote.url = "github:nix-community/lanzaboote/v0.3.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";

    redacted.url = "git+ssh://git@git.geklaute.cloud/emilylange/nixos-config-redacted";
  };

  outputs = { self, ... } @ inputs:
    rec {
      inherit (inputs.nixpkgs) lib;

      pkgs = import inputs."nixpkgs-small" {
        system = "x86_64-linux";
        overlays = import ./overlays;
        config.allowAliases = false;
      };

      colmenaHive = inputs.colmena.lib.makeHive {
        meta = {
          nixpkgs = pkgs;
          specialArgs = {
            inherit inputs self;
            inherit (inputs) redacted;
          };
        };

        defaults = { lib, config, name, ... }: {
          imports = [
            ./machines/${name}.nix
            ./presets/common/defaults
            ./presets/server/defaults
            (import "${inputs.lix-module}/module.nix" { inherit (inputs) lix; })
          ] ++ (import ./modules/module-list.nix) ++ inputs.redacted.private-modules;
        };

        futro = { };
        netcup01 = { };
        wip = { };
        smol = { };
        spof = { };
      };

      nixosConfigurations = {
        ryzen = lib.nixosSystem {
          specialArgs = {
            inherit inputs self;
            inherit (inputs) redacted;
          };
          system = "x86_64-linux";
          modules = [
            ./machines/ryzen.nix
            ./presets/common/defaults
            ./presets/desktop/defaults
            (import "${inputs.lix-module}/module.nix" { inherit (inputs) lix; })
            { nixpkgs.overlays = import ./overlays; nixpkgs.config.allowAliases = false; }
          ] ++ (import ./modules/module-list.nix) ++ inputs.redacted.private-modules;
        };

        frameless = lib.nixosSystem {
          specialArgs = {
            inherit inputs self;
            inherit (inputs) redacted;
          };
          system = "x86_64-linux";
          modules = [
            ./machines/frameless.nix
            ./presets/common/defaults
            ./presets/desktop/defaults
            (import "${inputs.lix-module}/module.nix" { inherit (inputs) lix; })
            { nixpkgs.overlays = import ./overlays; nixpkgs.config.allowAliases = false; }
          ] ++ (import ./modules/module-list.nix) ++ inputs.redacted.private-modules;
        };

        # nix build -L .#nixosConfigurations.lix-iso.config.system.build.isoImage
        lix-iso = lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            (import "${inputs.lix-module}/module.nix" { inherit (inputs) lix; })
          ];
        };
      } // colmenaHive.nodes;

      /*
        Get the first address of a network interface.

        Example:
        headAddress config.networking.interfaces.eth0.ipv6
        => "2001:db8::1"
      */
      headAddress = interface: (lib.head interface.addresses).address;

      ## dummy derivation to build (and cache!) all `nixosConfigurations`
      ## `nix copy --no-check-sigs --from /tmp/nix-cache .#outPaths`
      ## `nix build .#outPaths`
      ## `nix copy --no-check-sigs --to /tmp/nix-cache .#outPaths`
      outPaths = pkgs.linkFarmFromDrvs "nodes"
        (lib.mapAttrsToList (n: v: v.config.system.build.toplevel) nixosConfigurations);
    };
}
