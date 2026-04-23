{
  pkgs,
  lib,
  ...
}: let
  rev = "cb0023562317199468b3bc995bd87a52076d14f4";
  shortRev = builtins.substring 0 7 rev;
in
  pkgs.rustPlatform.buildRustPackage {
    pname = "brush-shell";
    version = "0.3.0-unstable-${shortRev}";

    src = pkgs.fetchFromGitHub {
      owner = "reubeno";
      repo = "brush";
      inherit rev;
      hash = "sha256-xWHcyKuxV0n3blqqLzV5zL9t/UCnVnffdX2CErvglX0=";
    };

    cargoHash = "sha256-PkBLUP3tDRDDvmtlwnoBdEwJ4Djb4a/ETorjtCjbB68=";

    cargoBuildFlags = ["-p" "brush-shell"];

    # Tests require bash as oracle and network access
    doCheck = false;

    meta = with lib; {
      description = "Bash/POSIX-compatible shell written in Rust";
      homepage = "https://github.com/reubeno/brush";
      license = licenses.mit;
      mainProgram = "brush";
      platforms = ["x86_64-linux"];
    };
  }
