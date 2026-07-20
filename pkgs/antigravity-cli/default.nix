{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.1.4";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.4-6277569641840640/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-oIih8jHYVltmc87Nhlb8NQTknInpxrjEEWk3tf5wacjc+6eLuyvFwP+Oh7pk/iG2PbcAHjpXlFBJJ9rZ6J2pcw==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.4-6277569641840640/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-jTxGQwOyNbbywtRB7KB7DBzDXvpo964WsWelotSTc5A+/faGs+QQY0JPDPDFtdXrBW95RNreer8bjrIly4xDjA==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.4-6277569641840640/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-ZP9TWUY0sURHSq+iiicxPE4TbMie428D9JDncgIiN5oiPK5gs0DqLRCs46hjRxE63qnGVzBavghX1Zx7AwVrig==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.4-6277569641840640/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Aq3QAk37ZLlBFb05220hwjt9nYsQ6EH2zmXxZgb/8uWiSRnFAdXCGJS81Fnt3gen9jzmHUe4Iud2Mhb0cR+6HQ==";
    };
  };

  src = fetchurl (
    sources.${stdenv.hostPlatform.system}
      or (throw "antigravity-cli: unsupported system ${stdenv.hostPlatform.system}")
  );
in
  stdenv.mkDerivation {
    pname = "antigravity-cli";
    inherit version src;

    sourceRoot = ".";

    nativeBuildInputs = lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;
    buildInputs = lib.optional stdenv.hostPlatform.isLinux stdenv.cc.cc.lib;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 antigravity $out/bin/agy
      runHook postInstall
    '';

    meta = {
      description = "Google Antigravity CLI — terminal agent (Gemini CLI successor)";
      homepage = "https://antigravity.google";
      changelog = "https://antigravity.google/cli/release-notes";
      license = lib.licenses.unfree;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      mainProgram = "agy";
      platforms = lib.attrNames sources;
    };
  }
