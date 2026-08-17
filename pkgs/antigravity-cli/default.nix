{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.1.13";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.13-6057583128215552/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-icaIG2wZmcuCNucYHCGSro83KwQTOWwPe8/4PSesnAzBICeVzA1insHsv0k30cKUz09eT5+OBbHpcuJxmDE0Qg==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.13-6057583128215552/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-0vNkKHPjKDJl6/TU4syMNlLf9aCxk6M+v+Dd7WhSHdArTCjtkv9UeE9qYmfpXIB7TYGU6KbWGdQ0hjirXIENRA==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.13-6057583128215552/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-IVoPjh5scVX5wB9FgPUKKgGxeibBwCjqZTfPHIj6mkLxo6INA+pFnE4/KkKdO7c39JsfG9bTSkrX0QQbOc/85g==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.13-6057583128215552/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Mh4DQlUbDRGXodazc2PRnUt5k23rEDUjxs3aR88aNw3R/rv1ERsRItgygdMJSbbvyNzAO7cpSKipFSvAzow7FQ==";
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
