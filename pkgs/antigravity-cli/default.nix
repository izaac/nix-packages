{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.1.27";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.27-5211191891591168/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-eT1LnqLAjZp+ULr6As/IwZQkvWDW6D+RQI1F+cbUznml1Xb+3lvvFk2COr+E+BNZoUtMpmWVLEewp8/XQ7tpwA==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.27-5211191891591168/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-7UX2kweFqktC8U4HrOHJ2RqU+3bnYPVKy9fT05UeH5V/1Fag2uKjEk3Zo7aJv3r7fJMDo+S6lQN/wQBjQk2b+Q==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.27-5211191891591168/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-otuBTPfuOlBELK8JB6Rw+iBz1ti9bNEDn6wgIrCrtKFadbcBkaDNvAgYOQe/rCOz+aS62plFUsNOm5/4BjeLyg==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.27-5211191891591168/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-zWJ/eY4Fn4Soi/4h295UzFJi4tk9GUPxIOtLOGgj9KH3xKV9TQ+HZVdwm2BhpMAvH8ExV/AEfF328wCvpHHkEQ==";
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
