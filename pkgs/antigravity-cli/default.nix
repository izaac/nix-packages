{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.0.6";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.6-6458082025406464/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-G1eXe+CDmLA0TvUBkIloPAqumClUXN8wVsmh0CuUnqmNtuZD75bvT2h3ZU9NSNUmcDXviidlKo4CP2W5HAbfdg==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.6-6458082025406464/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-+ZZ/qMMYwx94vML4E8dU4Ob3usgDAURWHVswMVVyDajKBIXspLbIFCmRcFJqHozJ3J7CCR/Mwem9uGTduWEHVw==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.6-6458082025406464/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-qFMu84KRak5pJlCpQyOvyAo1Mh0tyrHTe/JfZL3SDIoGF0B1Y1ppKy8AM6C4igJ9cgxyLi036pInf/iBq6MFvw==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.6-6458082025406464/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-3k/XXkeDPPHxRYu492NI49zD+GKjvGHxgb+MRNlQPImAy2m2hxUfgOIveaVc/AfqeUq1T2ZY2XqsKzk6OCKiuw==";
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
