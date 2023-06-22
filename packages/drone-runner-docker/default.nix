{ pkgs, ... }:

pkgs.drone-runner-docker.overrideAttrs (finalAttrs: previousAttrs: {
  patches = (previousAttrs.patches or [ ]) ++ [
    (pkgs.fetchpatch {
      ## PR: "Add option to enable IPv6 support in docker networks"
      ## https://github.com/drone-runners/drone-runner-docker/pull/58
      url = "https://github.com/drone-runners/drone-runner-docker/commit/53a5e2344779878295e9a4b4f79cd96414c06e2a.patch";
      hash = "sha256-sIi1PewmGf7kRU+6blfShCZRkxAp8RWp6YP/P9nbC1Q=";
      name = "58.patch";
    })
  ];
})
