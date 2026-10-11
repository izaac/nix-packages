{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.2.17";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.17-6683332533157888/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-0OvmEvfPwhyN6eenpilksiRdid21cNXifoPmGizHbLOOgLbrO91xvvaD66AnxKl9zOTO2B9H+Cd2MjTQzT7Fkg==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.17-6683332533157888/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-ojFvWwLtjjVMkilSX3oyOcHiSfM6HQRChnxoo5skU2VOjQxIw2v5eyo/zvSvwHp/ee6iqJULVxCruHd9Gj03Vg==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.17-6683332533157888/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-sXvSRDhfUay2bSd2RinKspPBs32dafWf2QQhquy0ntIk1aSl8r39NZWJIuBuos6YkJ8QsDkU8dyyTikPTh7GKQ==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.17-6683332533157888/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-kpZwOzt5p9qf+D/zsTh2JjnoUMcRhrYr619ZEKezeZ2V2F7DAyDVXUyY2SxeZcevdUQ81R4yRp3Rwr5e6Cns/Q==";
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
