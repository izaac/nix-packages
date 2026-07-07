{pkgs, ...}:
pkgs.stdenv.mkDerivation {
  pname = "pd";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [pkgs.makeWrapper];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp pd.sh $out/bin/pd
    chmod +x $out/bin/pd

    wrapProgram $out/bin/pd \
      --prefix PATH : ${pkgs.lib.makeBinPath [
      (pkgs.callPackage ../proton-drive-cli {})
      pkgs.fzf
      pkgs.jq
      pkgs.coreutils
      pkgs.findutils
    ]}
  '';

  meta = {
    description = "Fuzzy Proton Drive browser that downloads files to cwd";
    platforms = pkgs.lib.platforms.linux;
  };
}
