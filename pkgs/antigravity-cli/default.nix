{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.4.2";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.2-4835981233356800/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-Sjk6/BNpzulOgXwbQwyRKNArEuvU1XA6zlzUeyMz4hbWc/sAl8v3GV91exEBY7qYUOnuo/27rd1LJWaLgsA/BQ==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.2-4835981233356800/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-9GVUaNMwPmA5y88aMHaePLXE4W0Un7oNCOg/kfDysHy2I6StuGFcp6j8c78kRTAeDhq4LqifaqRMvZqelnA+GQ==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.2-4835981233356800/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-xcUReRcuZJ1wW4aZT5+lQuamJiduUp50clc7PfE5pxUAQkJQIT/1pJi33+xjX7KhAiJEMe/KBUsaCVXIWPHFtQ==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.2-4835981233356800/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-KK608KTFDYxZGwmMObmoWwnGNzI15D4nZp6EV4z+oWFul+HurkD46WlQpl+2tR+N2RlImLS8afEIRCXXirzUQg==";
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
