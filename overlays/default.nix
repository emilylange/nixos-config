[
  (final: prev: {
    fasttext = prev.fasttext.overrideAttrs (o: {
      meta = (o.meta or { }) // { mainProgram = "fasttext"; };
    });
  })
]
