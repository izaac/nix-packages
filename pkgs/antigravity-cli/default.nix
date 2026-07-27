{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.1.7";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.7-5951805767680000/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-cg1af/JWql3WcSUTzV62/gMc+edSOjO8vad1USDO1Tu2T/mFtALOBo5YleD/s0jCYyVFA5od3m2q1ZHxZNWFLw==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.7-5951805767680000/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-a0I2bDkmmUeFMBr0PgH1lcW45D61IRZtmEeFOTaLDar7MhEAD7IoCt5qN9oKbEOO8oq8LIK2yCYwF7JFh4/FBg==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.7-5951805767680000/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-QKtkzQ8l/r1PSHYtP6thnCPwtK8w18lag+vTSnrTezRsos19WTtdYK6vg4rN8+4GHnR9fKE5jl+tn/xWd4G6MQ==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.7-5951805767680000/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-cS/wIqQGFkFLRKkESwnHZipFth/lutoIvQCvl7ZvG6oKk3S7mBN+1VnpOnSZ+PqDLWVYv6N7IKn2ErW+JF8xtw==";
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
