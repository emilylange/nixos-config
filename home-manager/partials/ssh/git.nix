{
  git = {
    host = builtins.concatStringsSep " " [
      "github.com"
      "gitlab.com"
      "gitea.com"
      "git.geklaute.cloud"
    ];
    user = "git";
    identityFile = "~/.ssh/id_ed25519-git";
  };
}
