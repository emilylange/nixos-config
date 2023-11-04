builtins.mapAttrs
  (name: value: {
    identityFile = "~/.ssh/id_ed25519_sk-gkcl";
    extraOptions = {
      PasswordAuthentication = "no";
      PreferredAuthentications = "publickey";
    };
  } // value)
  {
    "netcup01" = {
      hostname = "2a03:4000:3e:1f8::1";
      port = 22222;
    };

    "futro" = {
      hostname = "192.168.10.12";
    };
  } // { }
