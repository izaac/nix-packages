{
  pkgs,
  lib,
  ...
}: let
  version = "brush-core-v0.5.0-unstable-2026-07-11";
in
  pkgs.rustPlatform.buildRustPackage {
    pname = "brush-shell";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "reubeno";
      repo = "brush";
      rev = "7521022efcd3c857f3829c1f9d69b67b0a262922";
      hash = "sha256-0UeeI/Gszj8KG1PL8yFz8jqc2jo4WP4r+gyeixWGhpQ=";
    };

    cargoHash = "sha256-QV8NSTtUX/DqXLmw1CkKJ2k4nxh6xLPG1cnjEwQqTxE=";

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
