{
  pkgs,
  lib,
  ...
}: let
  rev = "d2feccf1517bd14d7b3e878e4b598d8ec3767b4f";
  shortRev = builtins.substring 0 7 rev;
in
  pkgs.rustPlatform.buildRustPackage {
    pname = "brush-shell";
    version = "0.3.0-unstable-${shortRev}";

    src = pkgs.fetchFromGitHub {
      owner = "reubeno";
      repo = "brush";
      inherit rev;
      hash = "sha256-iDbOcrMQz5pEgzAOABdtPNn/6ZEd4lw7M4J1ttmrpL4=";
    };

    cargoHash = "sha256-RMwgcGPYvhYSazjVzbVoVG8bCPR4qJLcTgt1tUr4Iso=";

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
