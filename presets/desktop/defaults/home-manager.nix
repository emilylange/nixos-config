{ config, inputs, redacted, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  ## enable dconf for gtk settings
  ## see https://nix-community.github.io/home-manager/index.html#_why_do_i_get_an_error_message_about_literal_ca_desrt_dconf_literal
  programs.dconf.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    ## Move existing files on activation by appending the
    ## given file extension rather than exiting with an error
    backupFileExtension = config.system.nixos.version;

    extraSpecialArgs = { inherit inputs redacted; };

    users.me = { ... }: {
      imports = [
        ../../../home-manager
      ];
    };
  };
}
