{ inputs, redacted, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  ## enable dconf for gtk settings
  ## see https://nix-community.github.io/home-manager/index.html#_why_do_i_get_an_error_message_about_literal_ca_desrt_dconf_literal
  programs.dconf.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    extraSpecialArgs = { inherit inputs redacted; };

    users.me = { ... }: {
      imports = [
        ../../../home-manager
      ];

      # forcefully overwrite some files that often cause conflicts when switching generations. E.g.
      #
      # > Existing file '/home/<user>/.config/gtk-3.0/bookmarks' would be clobbered by backing up '/home/<user>/.config/gtk-3.0/bookmarks'
      # > Please move the above files and try again or use 'home-manager switch -b backup' to back up existing files automatically.
      #
      # I've previously opted to set `backupFileExtension = config.system.nixos.version;` but this usually only delayed the very same
      # error by one switch (assuming no flake bump happened in the meantime).
      xdg.configFile."gtk-3.0/bookmarks".force = true;
      xdg.configFile."mimeapps.list".force = true;
    };
  };
}
