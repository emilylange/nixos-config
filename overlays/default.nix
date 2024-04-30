[
  (final: prev: {
    fasttext = prev.fasttext.overrideAttrs (o: {
      meta = (o.meta or { }) // { mainProgram = "fasttext"; };
    });

    # manual alias for pkgs.system because allowAliases is false
    # but colmena needs this in src/nix/hive/eval.nix.
    # TODO: fix colmena upstream
    inherit (prev.stdenv.hostPlatform) system;
  })
]
