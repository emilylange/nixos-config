{ ... }:

{
  programs.kitty = {
    enable = true;
    settings = {
      enable_audio_bell = false;
      update_check_interval = 0; ## disable periodic (24h) version update check
      scrollback_lines = 10000; ## increase from default 2000 lines
      scrollback_pager_history_size = 50; ## [in MB], only when using pager
    };

    # this used to be in the freeform programs.kitty.settings option, until https://github.com/nix-community/home-manager/pull/4629
    shellIntegration.mode = "no-cursor no-prompt-mark"; ## disable "click to move cursor" functionality but keep cursor block-y
  };
}
