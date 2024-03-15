{ pkgs, lib, ... }:

{
  programs.helix = {
    enable = true;
    extraPackages = with pkgs; [
      nil
    ];
    settings = {
      theme = "onedark";
      editor = {
        whitespace.render = "all";
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          formatter = { command = lib.getExe pkgs.nixpkgs-fmt; };
        }
      ];
    };
  };

  home.sessionVariables.EDITOR = "hx";
}
