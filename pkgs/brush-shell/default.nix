{
  pkgs,
  lib,
  ...
}: let
  rev = "e45ef40d8fcbc597305a59a20cab3132c5bee30a";
  shortRev = builtins.substring 0 7 rev;
in
  pkgs.rustPlatform.buildRustPackage {
    pname = "brush-shell";
    version = "0.3.0-unstable-${shortRev}";

    src = pkgs.fetchFromGitHub {
      owner = "reubeno";
      repo = "brush";
      inherit rev;
      hash = "sha256-rXmFFtbXAM8762d/6VKNZvnCVg2xchpm6/cEMdGa108=";
    };

    cargoHash = "sha256-SXxdoT++e9VLRGrOEBy8E8fi3sd+kgXycio386l2GXU=";

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
