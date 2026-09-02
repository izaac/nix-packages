{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.1.22";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.22-5711547746615296/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-QCJdSx8AlBLpBfCiNLo9UUhwONGtG4+hkzHIS+VWEKAfWwrZkW+4cRUcxFRWxrwwzAsepdq2wGFryPsmK83XqQ==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.22-5711547746615296/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-s3pxgzDrXicOHKcBNb+WSkB7pib7/3U3rFjglOoxvGI+bSFu8ZcYj+i1xG5vV67mSjt8niP8hVzv7kP+Q0F50w==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.22-5711547746615296/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-/C4XjdCE+6GadnOiTJKmCwysP4dTm8cxPy8Ci2Ms+T4ItJfZc9ZHBblZGlrtl4Emt8/LCjBCIL/aGM8QYVw2RA==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.22-5711547746615296/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-qBIRhb0cNFVBCtQeiOIDDqI31Ja45AzN4xO/YRwFUYQP3fRQtFyOGiV12YY8mQszJPGe7w9HmTbfi/xuToDTCw==";
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
