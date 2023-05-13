{ lib, ... }:

{
  options = with lib; {
    ## polluting the top level namespace lmao
    isServer = mkOption {
      type = types.bool;
      default = false;
    };
  };
}
