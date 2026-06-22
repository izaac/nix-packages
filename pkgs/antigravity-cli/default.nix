{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.0.10";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.10-6349723456634880/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-RXgoQPjOFCB+ybi5YuduZPDnTnkgAA8XYYD3IE4PieYcDkdcmitIWcyQ8IwhSEi52QrBw0TvmH95bidoIAeN8Q==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.10-6349723456634880/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-le3F/mw7Rburp2g+dIx+rqXxlQ9k7s8IPNU/O0GWH88T/atoxk1wLX5bdJxj3GOFxbAVmoXtxu0SqdGjI+Ye4A==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.10-6349723456634880/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-pUNnwJeNHhMw7s9UhjmM1Ma5DX/NOC3dpa/PxpjAY9bidIfmH9J/Ijl0z9fONavKSJssFF0PiOcYjSsYieJHYA==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.10-6349723456634880/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-/vBWEqKo8pNDAbe4c3tDVhNNNKzd+IYEbg1NfkV3wAcXqMEfjYT5WNmIm4dPw+5HVu5I7LoilWIxhXBfw+kGZw==";
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
