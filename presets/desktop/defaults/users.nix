{ pkgs, ... }:

{
  ## users :)
  users.users = {
    me = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
      ];
      shell = pkgs.fish;
    };
  };
  programs.fish.enable = true;
}
