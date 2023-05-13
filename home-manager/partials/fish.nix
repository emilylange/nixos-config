{ ... }:

{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      cat = "bat";
      rm = "trash";

      ## ping shortcuts
      p1 = "ping 1.1";
      p4 = "ping -4 gkcl.de";
      p6 = "ping -6 gkcl.de";
    };
    interactiveShellInit = ''
      ## disable greeting
      set fish_greeting

      ## prompt preset to base off
      fish_config prompt choose astronaut

      ## hook into `user@hostname`
      function prompt_login
        echo ' '
      end

      set __fish_git_prompt_color grey
      set __fish_git_prompt_show_informative_status 1
      set __fish_git_prompt_showcolorhints 1
      set fish_color_cwd --bold grey
      set fish_prompt_pwd_dir_length 0
    '';
  };
}
