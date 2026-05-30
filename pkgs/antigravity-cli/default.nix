{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.0.3";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.3-6260531212976128/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-9s+JDUlPX9AMaWtNLlQciU1bEP9Qv9n23AK5FThuCLYcVhQPFxFYmPxJ9KpFNFgTkwmPNdtwvpquIN/eO6V4fA==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.3-6260531212976128/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-D20ybvKOV+Rzx4JVgzFGNvoLzaUOJxF/89AZGW0EjXZK8phGkQovI43Iej+QBi4ptSUiMsfVhqhquq6pIWl+Ug==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.3-6260531212976128/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-Xl3k4rWpx4iTBpnQ9fcojq5K6R+3BdxuYvedlqZ2GfWOK6Q1fWwtu/1TCa648Wk06/CaVz72K0ibN+ksJ1THTg==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.3-6260531212976128/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-ssDSGHaum2+vYWSxW1c9duN59kPgQOd9Uo66+l1b2Ik8w8jr2aePr2e9fGdt1L/w8Cjzu7UI5UR2nWHePaa4sQ==";
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
