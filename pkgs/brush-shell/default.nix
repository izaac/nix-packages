{
  pkgs,
  lib,
  ...
}:
pkgs.stdenv.mkDerivation rec {
  pname = "brush-shell";
  version = "0.3.0";

  src = pkgs.fetchurl {
    url = "https://github.com/reubeno/brush/releases/download/brush-shell-v${version}/brush-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-iSWSSSnMq/nrp6gDs7obOnNSvyVR+8me0r1pcNMwd20=";
  };

  sourceRoot = ".";

  nativeBuildInputs = [pkgs.autoPatchelfHook];
  buildInputs = [pkgs.gcc-unwrapped.lib];

  installPhase = ''
    mkdir -p $out/bin
    install -m 755 brush $out/bin/brush
  '';

  meta = with lib; {
    description = "Bash/POSIX-compatible shell written in Rust";
    homepage = "https://github.com/reubeno/brush";
    license = licenses.mit;
    mainProgram = "brush";
    platforms = ["x86_64-linux"];
  };
}
