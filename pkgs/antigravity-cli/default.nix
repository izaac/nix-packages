{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.5.9";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.9-4515810895593472/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-0B6xO6d1Du0YkH8a6IYIZDceCtkGRBXo0DPSK0vXubTkx/liBYUgtFLWfbHDMWPZqInVWn3/oVlZbsbNkah7eQ==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.9-4515810895593472/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-FsYyoJuB9Zj3ZSvBEYCGH50u5ECP+hYdrcg7IBDeepzQVel7S0bNAZA+NcDovyHYJiRiunxfFozG2tqaw9UiwA==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.9-4515810895593472/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-Xz/RYSfeEim9l4UJZJsNd7YCeWKS9GWrDgAe3RQekCtLl1mZH3RM3jJkuJL3KZ6vym+65hnsqNskuYXX20DyXg==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.9-4515810895593472/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-aQzWpaX9sjVk+xsU9/auNo+jY2t2MPVsV0pt/A4nkaDluT1lFb4WUMiiaM+yhEDhucuqHFuFqnYqsltRwfzNpQ==";
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
