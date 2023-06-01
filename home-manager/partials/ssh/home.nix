builtins.mapAttrs
  (name: value: {
    identityFile = "~/.ssh/id_ed25519_sk-git";
    extraOptions = {
      PasswordAuthentication = "no";
      PreferredAuthentications = "publickey";
    };
  } // value)
  {
    "futro" = {
      hostname = "192.168.10.12";
    };
  } // { }
