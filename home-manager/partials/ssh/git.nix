{
  git = {
    host = builtins.concatStringsSep " " [
      "codeberg.org"
      "git.*"
      "github.com"
      "gitlab.com"
    ];
    user = "git";
    identityFile = "~/.ssh/id_ed25519_sk-git";
    extraOptions = {
      PasswordAuthentication = "no";
      PreferredAuthentications = "publickey";
    };
  };
}
