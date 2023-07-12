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

    "altra" = {
      hostname = "2603:c020:800b:36ff::abcd";
    };

    "futro" = {
      hostname = "192.168.10.12";
    };
  } // { }
