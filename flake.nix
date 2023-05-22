{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-small.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    colmena.url = "github:zhaofengli/colmena";
    colmena.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    redacted.url = "git+ssh://git@git.geklaute.cloud/emilylange/nixos-config-redacted";
  };

  outputs = { self, ... } @ inputs:
    rec {
      inherit (inputs.nixpkgs) lib;

      pkgs = import inputs."nixpkgs-small" { system = "x86_64-linux"; overlays = import ./overlays; };

      colmenaHive = inputs.colmena.lib.makeHive {
        meta = {
          nixpkgs = pkgs;
          nodeNixpkgs.altra = import inputs."nixpkgs-small" { system = "aarch64-linux"; overlays = import ./overlays; };
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
          ] ++ (import ./modules/module-list.nix);
        };

        altra = { ... }: { };
        futro = { ... }: { };
        netcup01 = { ... }: { };
        stardust = { ... }: { };
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
          ] ++ (import ./modules/module-list.nix);
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
          ] ++ (import ./modules/module-list.nix);
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
