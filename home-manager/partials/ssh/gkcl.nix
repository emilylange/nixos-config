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
      hostname = "192.168.10.13";
    };

    wip = {
      hostname = "2a01:4f8:190:441a::1";
      port = 22222;
    };

    wip-initrd = {
      hostname = "2a01:4f8:190:441a::ffff";
      port = 22222;
    };

    smol = {
      hostname = "2a03:4000:40:94::1";
    };

    spof = {
      hostname = "192.168.10.2";
    };

    spof-initrd = {
      hostname = "192.168.10.2";
      port = 2222;
    };
  } // { }
