{ lib, ... }:

{
  options = with lib; with types; {
    colors = mkOption {
      type = attrsOf str;
    };
  };

  config = {
    colors = {
      black = "#000";
      gray = "#6e6c7e";
      pink = "#ea76cb";
      white = "#fff";
    };
  };
}
