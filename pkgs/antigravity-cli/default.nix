{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.2.7";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.7-6731160148115456/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-/sdp1hHEr98K5y04vbJlLI4sjnHk9t6XonuA3aPFBCkWDZ4Dd2o2pZuIV8IOdng8SknLD+uLL1w7+SWwzAO7dw==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.7-6731160148115456/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-05+Tn/yAd2v9LcENt7mhobWGUPCBFfohBlwR0QiCxxIQ82jC5gYPJpZtGjPWst0rwZv9ZBBiMFr2VGxR1JRRGg==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.7-6731160148115456/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-SycaUzLmhBYIGl/M3AfF7aQu5+lkxG/Ju+xej50fv9N+65lThVzAgPmj7/hQuvqcsD95gPHwsc3Tx/lAKXKx8A==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.7-6731160148115456/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-4mAyzkIJhaGOcgtuwcCdg2Cu2FHT4zRRSMmgUreRiYmlK2LdLI20U1meo0G4spcgc3hG/9N92caLa8bs5KBZlA==";
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
