{
  pkgs,
  lib,
  ...
}: let
  rev = "72593cd56c919d78b49f6ef11b9ed0e26b72b03e";
  shortRev = builtins.substring 0 7 rev;
in
  pkgs.rustPlatform.buildRustPackage {
    pname = "brush-shell";
    version = "0.3.0-unstable-${shortRev}";

    src = pkgs.fetchFromGitHub {
      owner = "reubeno";
      repo = "brush";
      inherit rev;
      hash = "sha256-o6QKce4PNeie/D3RDommsWaw4vrei6vyDqs4FAE1DVA=";
    };

    cargoHash = "sha256-UCniXYFJP3OmXKFO6hvwVCS1PSXfKwFPWpJvq54+sEM=";

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
