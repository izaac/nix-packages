{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.3.3";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.3.3-5524738307653632/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-q+Pd9c8w062qWGrPUFIhqhlwL1ynGvPIsfmxpZdr2OXBUcQeozs5xBZ10lhDRio+jDgsBU9YDp1+FoiRnTtREA==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.3.3-5524738307653632/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-G/01A1diGaECF2wTV5ZlovOehKyGqQSxF9OzPz3XUfGUqGJJa61v/pFK1G0sh3uhK2wH5tsHEotwbSOCYv5DDA==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.3.3-5524738307653632/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-lwdax+0ICSj1jsPgvoOzgFf5gNQJJ6PQ2txUhQypmohPOMkL9cT27LPGEB8x11YFAEUDkMRoIIrH3iVgry33aw==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.3.3-5524738307653632/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-Beu0chScpGHpn3hwzoH73UjjhE9DuWp3jJgdmDQhYnxb0CWW3IIRzNMLTO4N+MpNF7aB9YfvIpSOpMcD6cf8vQ==";
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
