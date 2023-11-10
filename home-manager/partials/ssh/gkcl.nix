builtins.mapAttrs
  (name: value: {
    identityFile = "~/.ssh/id_ed25519_sk-gkcl";
    extraOptions = {
      PasswordAuthentication = "no";
      PreferredAuthentications = "publickey";
    };
  } // value)
  {
    netcup01 = {
      hostname = "2a03:4000:3e:1f8::1";
      port = 22222;
    };

    futro = {
      hostname = "192.168.10.12";
    };

    wip = {
      hostname = "2a01:4f8:190:441a::";
      port = 22222;
    };

    wip-initrd = {
      hostname = "2a01:4f8:190:441a::ffff";
      port = 22222;
    };
  } // { }
