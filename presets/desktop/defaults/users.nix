{ pkgs, ... }:

{
  ## users :)
  users.users = {
    me = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
      ];
      shell = pkgs.fish;
    };
  };
  programs.fish.enable = true;
}
