{ lib
, caddy
, xcaddy
, buildGoModule
, stdenv
, cacert
, go
}:

let
  version = "2.8.4";
  rev = "v${version}";
in
(caddy.overrideAttrs (_: { inherit version; })).override {
  buildGoModule = args: buildGoModule (args // {
    src = stdenv.mkDerivation rec {
      pname = "caddy-using-xcaddy-${xcaddy.version}";
      inherit version;

      dontUnpack = true;
      dontFixup = true;

      nativeBuildInputs = [
        cacert
        go
      ];

      plugins = [
        # https://github.com/caddy-dns/acmedns
        "github.com/caddy-dns/acmedns@18621dd3e69e048eae80c4171ef56cb576dce2f4"
      ];

      configurePhase = ''
        export GOCACHE=$TMPDIR/go-cache
        export GOPATH="$TMPDIR/go"
        export XCADDY_SKIP_BUILD=1
      '';

      buildPhase = ''
        ${xcaddy}/bin/xcaddy build "${rev}" ${lib.concatMapStringsSep " " (plugin: "--with ${plugin}") plugins}
        cd buildenv*
        go mod vendor
      '';

      installPhase = ''
        cp -r --reflink=auto . $out
      '';

      outputHash = "sha256-Gw4cm/BhFUUly2evnMJQU6ELEID/8EDSDVb263OV3tg=";
      outputHashMode = "recursive";
    };

    subPackages = [ "." ];
    ldflags = [ "-s" "-w" ]; ## don't include version info twice
    vendorHash = null;
  });
}
