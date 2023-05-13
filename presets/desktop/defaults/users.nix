{ pkgs, ... }:

{
  ## users :)
  users.users = {
    me = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "docker"
      ];
      shell = pkgs.fish;
    };
  };
  programs.fish.enable = true;
}
