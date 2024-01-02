{ ... }:

{
  xdg.configFile."nixpkgs/config.nix".text = ''
    {
      allowAliases = false;
    }
  '';
}
