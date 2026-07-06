{
  pkgs,
  lib,
  ...
}: let
  version = "brush-core-v0.5.0-unstable-2026-07-05";
in
  pkgs.rustPlatform.buildRustPackage {
    pname = "brush-shell";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "reubeno";
      repo = "brush";
      rev = "0300a84da5ce7135478c1831e5deacc2d5e7ec13";
      hash = "sha256-wvP1+WozDKDI8ztPfO9lPHyn7T6yvT5EVM/u5u6+4OQ=";
    };

    cargoHash = "sha256-7QHzxsgLr5tSNcbDSgRi5whK+a56Fu8M/9pcKTbeuo0=";

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
