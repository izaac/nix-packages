{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.1.19";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.19-4894004681244672/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-fDsxDIBoWty6cUmUIH64cPtIF0A5ddpGVVt9n63kRkh9o9j4l6oiDfvDD2AqtGGgFHpvezyCKP3r01lR4/JQ/Q==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.19-4894004681244672/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-SIw9rBx8qGap2pkPmohki/txdpkqCi0nYF47wQFD5bF69VLtmfC/QlDi1p/tbQ1fUGhMcpvwPyafK1K0RQNVjQ==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.19-4894004681244672/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-5vngw+DTJQmTfLaqX24ACWrtKnirPiH/3PBd278OK0dyOIGW2du8NWQAsWrcO6bS7LjY/a+pSJYE7Ts7vXdflQ==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.19-4894004681244672/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-VLaw4uL+1dXicMY1P4CXvSoOlm8HlG3tgGWmKTt57HvlmT9dPeXBLQaDszgipcuId5UJT/osb3e7cYOBbJKulg==";
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
