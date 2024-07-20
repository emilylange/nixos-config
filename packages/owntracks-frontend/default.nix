{ lib
, buildNpmPackage
, fetchFromGitHub

  # see https://github.com/owntracks/frontend?tab=readme-ov-file#configuration
, configJsFile ? "$out/config/config.example.js"
}:

buildNpmPackage rec {
  pname = "owntracks-frontend";
  version = "2.15.3";

  src = fetchFromGitHub {
    owner = "owntracks";
    repo = "frontend";
    rev = "v${version}";
    hash = "sha256-omNsCD6sPwPrC+PdyftGDUeZA8nOHkHkRHC+oHFC0eM=";
  };

  npmDepsHash = "sha256-sZkOvffpRoUTbIXpskuVSbX4+k1jiwIbqW4ckBwnEHM=";

  # override npmInstallHook
  installPhase = ''
    mv dist $out
    cp "${configJsFile}" $out/config/config.js
  '';

  meta = {
    homepage = "https://github.com/owntracks/frontend";
    description = "Web interface for OwnTracks built with Vue.js";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ emilylange ];
  };
}
