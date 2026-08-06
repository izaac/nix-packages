{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.1.10";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.10-6423386432339968/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-5k1OWO3g+EQPKz3AIfnW02sF9cL3TVqSFcHxGyDVNsjC4CD0zlJXqmfpQOlMlNWhbTqmRhzaGO5/PnTTogyhrA==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.10-6423386432339968/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-LWTE4J6yLIJLwpjKYeSMsOYmiDU9tBIplrLku6jJoVcNLL9uZFLtfvMN8JQL+PBYeJ5Gau1SZMGuLkYT7KW1cw==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.10-6423386432339968/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-DtlRl+psUD5g/J9l0DUvznM7PW9bihba6XG/6Rf+mEzH2srI/rArpxq2rauln5nx/3QH+V67yvj+wwQH0+j7sA==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.10-6423386432339968/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Yj+fu9kGmhrQ1xq35iNbWyhuGbEGfkFk0fm7elzoZtIeSpVduo7jl/6viwdnic2WZNomFpmF77WsfUKQGGgL0Q==";
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
