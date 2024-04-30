{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    meslo-lgs-nf ## ttf-meslo-nerd-font-powerlevel10k
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
}
