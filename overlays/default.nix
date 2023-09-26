[
  (final: prev: {
    matrix-synapse-unwrapped = prev.matrix-synapse-unwrapped.overrideAttrs (finalAttrs: previousAttrs: {
      patches = (previousAttrs.patches or [ ]) ++ [
        ./matrix-synapse-unwrapped/dont-change-roomstate-on-displayname-change.patch
      ];

      doCheck = false;
      doInstallCheck = false;
    });
  })
]
