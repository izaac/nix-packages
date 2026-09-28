{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.2.12";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.12-5784551402897408/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-1fD+dDPLfEPqh4wHYnpP24LSGPO+9eZDYmb12f3S3xRVI0U7m+DEJQORpkoAf19C9/r/eXvCstUC5++0h044Og==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.12-5784551402897408/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-4vEJYBl++/JFXtsShK5oaCHiRJCDZ/UHvLag0PYW6UXT7sXN8ptBu81/Ywgm0OniM/RXGE0WlvqR6B1qftRAyQ==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.12-5784551402897408/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-B+VoM0YLyJmepE9/xM/3leAwSgigXl4pbWCWrI4e8VyVrua2koA3NLt/SI5BbIvIC+ZA36cInZJ/552+/bVtIQ==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.12-5784551402897408/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-krzU0ZdrVw1vBTobVxbi8pYsIso892V6P8tmsFsPVSP6LW8YmfFXwJtmq9osL4GTgQGtfNMYReHtqPJ3rdwrjg==";
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
