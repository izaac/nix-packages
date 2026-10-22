{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.4.5";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.5-4952523841339392/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-/TDo0lbijEptD1/dqg90tHyMWo6foihcsD+FCT6Q7KBAbxwvpXoDhruCDiHtQn4nwjFaAUU9/aQBwiI7JjmrMA==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.5-4952523841339392/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-z2AAS0gBWic33LVs4RIn/vOnIvLpMpwTMY4pCVHjUMOVEYvYaAwQQrL97p0urQX7hLsllvotABKkS8BoZV006w==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.5-4952523841339392/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-IHdclVTX2J6uFiF3kTOri8QwW9CZa2P2ceCy7eVNooZqIf38mRmX9QN9omBAkU9bOWnYzyBLj+WU5PYBrHbkdg==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.5-4952523841339392/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-yU7MxPASF4fmLpa0ZCbBfftH7KwyTMXvP5ERMSuNygS/X8f1C64XJwxIaVZ5iuwLOKX+o1mQydXbQV7JCviMjw==";
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
