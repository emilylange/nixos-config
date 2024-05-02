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
      home = "/home";
    };
  };
  programs.fish.enable = true;
}
