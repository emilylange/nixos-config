{ pkgs, ... }:

pkgs.drone-runner-docker.overrideAttrs (finalAttrs: previousAttrs: {
  patches = (previousAttrs.patches or [ ]) ++ [
    (pkgs.fetchpatch {
      ## PR: "Add option to enable IPv6 support in docker networks"
      ## https://github.com/drone-runners/drone-runner-docker/pull/58
      url = "https://patch-diff.githubusercontent.com/raw/drone-runners/drone-runner-docker/pull/58.patch";
      sha256 = "sha256-sIi1PewmGf7kRU+6blfShCZRkxAp8RWp6YP/P9nbC1Q=";
    })
  ];
})
