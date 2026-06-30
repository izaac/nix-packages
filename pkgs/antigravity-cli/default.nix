{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.0.13";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.13-5758107482193920/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-+L4IjOuQ53UDsEA564ZX8f+sKbqzf5BYwlh/rzZBBZAOe3L+kxF0TIP7Gfb58LIDa2O8Acej//emq/6cAhZKbw==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.13-5758107482193920/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-FnGOpYvRYDbncIBRTU7EueN6JVAymDZEANm5Jh6vuyi7NjEkecn9VuSogC5vmJrnOj8lw1Xf1FC0SZMZukjh+g==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.13-5758107482193920/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-W8uDJvQPGbBAcXzZioes82hi5HN04w6KtyJ4yLPQwjSQygSN88tELWiZoLiy5/JcyMlfgn0BR2XjRBZb/ugDcA==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.13-5758107482193920/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-JmPgd7s9orTwTLleFPbcwM3ZX8EfGbDE9hQeBG7IEPiZCt54X4ss/5OK1vw74NzXou38Ki5VVMbQ+fpRalm5mg==";
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
