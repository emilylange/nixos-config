{
  git = {
    host = builtins.concatStringsSep " " [
      "codeberg.org"
      "git.dn42.dev"
      "git.geklaute.cloud"
      "gitea.com"
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
