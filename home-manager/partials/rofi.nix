{ config, ... }:

{
  programs.rofi = {
    enable = true;
    font = "MesloLGS NF Regular 12";
    extraConfig = {
      show-icons = true;
      drun-display-format = "{icon}{name}";

      modi = "drun,window";
      display-drun = "Start:";
      display-window = "Jump to:";
    };
    theme =
      let
        inherit (config.lib.formats.rasi) mkLiteral;
      in
      {
        "*" = with config.colors; {
          background = mkLiteral black;
          primary = mkLiteral gray;
          white = mkLiteral white;

          background-color = mkLiteral "@background";
          text-color = mkLiteral "@white";
        };

        window = {
          width = mkLiteral "25%";
          border = mkLiteral "2px";
          border-color = mkLiteral "@primary";
        };

        prompt = {
          enabled = true;
          padding = 2;
        };

        entry = {
          padding = 2;
        };

        "mainbox, error-message" = {
          padding = 12;
        };

        inputbar = {
          margin = mkLiteral "0 0 5 0";
        };

        element = {
          border = mkLiteral "0 0 3 0";
          border-color = mkLiteral "@primary";

          margin = mkLiteral "2 0";
          padding = mkLiteral "10 5";
        };

        "element selected" = {
          border-color = mkLiteral "@white";
        };

        element-text = {
          highlight = mkLiteral "None";

          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };

        ## I would like to make the selected element bold
        ## (but not any of the unselected), but I don't know
        ## how nor if that is even possible :(
        "element-text selected" = {
          highlight = mkLiteral "bold";
        };

        element-icon = {
          size = 22;
          padding = mkLiteral "0 3 0 2";
          background-color = mkLiteral "inherit";
        };

        listview = {
          columns = 1;
          lines = 10;
          scrollbar = false;
        };
      };
  };
}
