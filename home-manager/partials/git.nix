{ pkgs, config, redacted, ... }:

{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    userName = "emilylange";
    userEmail = "git@emilylange.de";
    lfs.enable = true;
    signing = {
      signByDefault = true;
      key = null; ## let GnuPG decide what signing key to use
    };

    extraConfig = {
      init.defaultBranch = "main";
      commit.cleanup = "scissors";
      commit.verbose = true;
      pull.rebase = true;

      merge.conflictStyle = "zdiff3";

      ## ask for passwords in terminal instead of `x11-ssh-askpass`-GUI
      core.askPass = "";

      ## store passwords/tokens in gnome keyring
      credential.helper = "${config.programs.git.package}/bin/git-credential-libsecret";
    };

    ## per-directory/workspace git config (e.g. user.name/user.email)
    ## Example:
    # includes = [
    #   {
    #     condition = "gitdir:~/dev/example/";
    #     contents = {
    #       user = {
    #         name = "name lastname";
    #         email = "name@example.com";
    #       };
    #     };
    #   }
    # ];
    includes = redacted.hm.git.includes;
  };
}
