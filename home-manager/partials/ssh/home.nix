builtins.mapAttrs
  (name: value: {
    identityFile = "~/.ssh/id_ed25519-git";
  } // value)
  {
    "rpi3" = {
      hostname = "192.168.10.10";
    };

    "futro" = {
      hostname = "192.168.10.12";
    };

  } // { }
