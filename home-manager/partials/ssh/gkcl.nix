builtins.mapAttrs
  (name: value: {
    identityFile = "~/.ssh/id_ed25519_sk-git";
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

    "stardust" = {
      hostname = "2001:bc8:1830:316::1";
    };

    "altra" = {
      hostname = "2603:c020:800b:36ff::abcd";
    };

  } // { }
