{ pkgs, ... }:

{
  hardware.sane = {
    enable = true;
    brscan5.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gnome.simple-scan
  ];

  users.users.me.extraGroups = [ "scanner" "lp" ];
}
