{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.0.8";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.8-5963827121094656/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-eEJqYfkpXXUoXZzdOem53Cc2NGRoySzoam/eG8x6nW3TLHvtGQOl3qzYdKBddbq/W5B+mRoRetY/M1SBE8Ybwg==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.8-5963827121094656/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-mCs0Te/S5jsI1KnvYIp3Cro6kumkEY0xjgCC8pdDRX6KFqrxwA98Ot51wtB671qPpdpmDkCMsZm0eod4sxIooA==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.8-5963827121094656/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-/5nMNqr6uaN73u9rosycHf7vrxMwUuIaZarsRt1almA9W0g1K8fVHUbl22PCqcBcXRImtpQAwBzKAZUhfy3OQQ==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.8-5963827121094656/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-j8ZX7qOhPAZixhS6QFHwQFDLCrunVVUYqts22I2n070hKuTMbPQ5IDiyFlaJaXmuqzL4vwXIDmn8cgx2UQNGNg==";
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
