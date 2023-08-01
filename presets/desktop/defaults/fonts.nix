{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    meslo-lgs-nf ## ttf-meslo-nerd-font-powerlevel10k
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra
  ];
}
