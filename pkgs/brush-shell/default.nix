{
  pkgs,
  lib,
  ...
}: let
  version = "0.4.0";
in
  pkgs.rustPlatform.buildRustPackage {
    pname = "brush-shell";
    inherit version;

    src = pkgs.fetchFromGitHub {
      owner = "reubeno";
      repo = "brush";
      tag = "brush-v${version}";
      hash = "sha256-zG6ho/QECzLC/evOUdo9mYXoh4xA2PF+BQvnCsLZiNg=";
    };

    cargoHash = "sha256-NSvlLiLp0kdnWNUSIateGkscL5as+b00d54CP3sEakI=";

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
