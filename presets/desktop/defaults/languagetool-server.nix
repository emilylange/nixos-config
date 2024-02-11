{ pkgs, lib, ... }:

{
  services.languagetool = {
    enable = true;
    port = 1234;
    settings = {
      fasttextBinary = lib.getExe pkgs.fasttext;
      fasttextModel = pkgs.fetchurl {
        # https://fasttext.cc/docs/en/language-identification.html
        # > These models were trained on data from Wikipedia, Tatoeba and SETimes, used under CC-BY-SA
        # TODO: package this fasttext model in nixpkgs
        url = "https://dl.fbaipublicfiles.com/fasttext/supervised-models/lid.176.ftz";
        hash = "sha256-jzRyz+hzintgmejpmcPL+uDc0VaWqsfXc4qAOdtgPoM=";
      };
    };

    # official LanguageTool extension on Firefox
    allowOrigin = "moz-extension://c827f42b-4fff-4d66-82de-17f356f24332";
  };
}
