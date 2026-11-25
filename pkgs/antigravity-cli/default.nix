{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.5.17";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.17-4823843970351104/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-calnqhbgq12HGWvNZ3ITC9q1Wy/XaM0k0hsdpAH/n2AoC5dsrT3BSi1kYjOw6vjK+HxJDu1zBE1UVQy7PY1n0g==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.17-4823843970351104/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-5PCG0HMLMlz9Q46pA5bueOsjoxEO9/eSgkyIF7jQQyRit7X5Gz2TP8GTKm9Lpz3lBeLpb0REjJ+yQnKS6tcW9w==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.17-4823843970351104/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-Ygbq74KWkgg5dp23qEL5WbfVi0dRkp6A8nz7CH3ZC6SJbM/sQVek4F47neUelj9MNEzQCnfH3jHAhifbtHpjCA==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.5.17-4823843970351104/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-IJ5tLpOPLC65CNbU/9ahMKBYsy6XqhbPTn4pzAzToIhnxq9FIr1B63YqflBe7kGECaiIfCzi0k2KvWbiRra5cg==";
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
