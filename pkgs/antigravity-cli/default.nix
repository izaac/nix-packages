{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.1.11";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.11-4956531888881664/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-MtZFKc8DWrl5A1IGndDfRSXXySC0KHLeF3XmVFXnf9mDs3pt7oGmNFsGDJjV81Bym7XirogbvagPRrdIevRYjQ==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.11-4956531888881664/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-+xrKzb3mBqYKgAK23AqMmAC7hK7zrdBp+EP2/6Pvqv5KUvzkQFBcbxauvWsSV8zl7PrsLbqyFzLGJZQ0IjGM2w==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.11-4956531888881664/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-EiK9BNtU6NQH9YBB5FnFxnTOEzULM7YurtlC1GAW2xQiStUksyQzrCvWwxDJUZP5TzLNZ9ZjslKtT1aXcprJug==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.11-4956531888881664/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-ikEOIDUKXSJVJv3kMWijdCYl2tMPQ9JUQj342Uektvh56tEmgBpSfj/yVcUI7S1e3GNSzvtIioSciIXAiVzSHw==";
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
