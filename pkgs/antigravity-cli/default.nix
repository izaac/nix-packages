{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.1.1";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.1-6269367663591424/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-/OutgkfgRTCX4rJtg5NxyI3wQOb7GPrD/YByhRGUc5z0YkBBRptX9Sm8nC4RQKbOTNXnFE5k5u/FYFqfEKhitw==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.1-6269367663591424/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-bT2Jx7iNTiLi7vk3znMTRSmWV6x6FCNqk6X53OZ+tyUYRczJgEsKsYgRJf9hZTEc5zxpM8E3bsO5ZmWalHU+YA==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.1-6269367663591424/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-gKF1Bvb5sc4jceeLLer4mrWutK2uHGb1EAFXNQU93cY84JdaNYy8zEIIsCUQOZ5L4S7iiiShbd99gLuYL4/Ihw==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.1.1-6269367663591424/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-KZPEtD0nA895aEjhoCtx4uBYg4fY3CQkQ1IH7tu8IJclHKC6MhuZ02Q1j35umN8awXV8H17ayo1Tq6omEj5/SQ==";
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
