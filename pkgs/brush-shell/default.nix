{
  pkgs,
  lib,
  ...
}: let
  rev = "3341f35d76d47ad2ccf51f0aab1d88b07e5a2dab";
  shortRev = builtins.substring 0 7 rev;
in
  pkgs.rustPlatform.buildRustPackage {
    pname = "brush-shell";
    version = "0.3.0-unstable-${shortRev}";

    src = pkgs.fetchFromGitHub {
      owner = "reubeno";
      repo = "brush";
      inherit rev;
      hash = "sha256-CXNyg51A8IMZkec9jlsiNyKdSkoLDpbRAGDRSbMTbGE=";
    };

    cargoHash = "sha256-9ZODDzfZI29Let5Yf0RYfV9vjTeH1VUAvyO8/USZ8UQ=";

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
