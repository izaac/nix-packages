{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.5.3";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.3-6604829099950080/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-42PhsX2qrCWJ8Y5pc0KcA5/VpeXBXpwIUvo0mDbzmSsQ/oRzK8jYyCCOFJ8DBPFaup3saW0S7+7QORdJLAWA6w==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.3-6604829099950080/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-wvrIGLPBuyJAed8DpxTMuplyi2o6QdhtJHqy/rhYKkOEDFAy8cK3XnJmdiPVUD5//aJxLE83tu4Z+Zw/z7Jbrg==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.3-6604829099950080/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-hl9uw9anvd/zpb/9pt8S2y34q/7fMGSstEJtsuwM5Z3j1J0TeJYN96Rkb/29dGAfIxhPDSOr/BzWcXob0p5pIg==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.3-6604829099950080/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-MhVlbP5TNrzjEDZfYd58hbSUahTeUGdHg3EG36+Ujc/zA8R+ZI4G+7tzqHAlOOrhceZ18pEOT0mygFSQGLRulQ==";
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
