{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.0.16";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.16-4893150192467968/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-LjNi+zYNNQKFw6eYkXcmUupWYIEh5OiQkavlU+ggPDeeMLrIa94QnswLMmbLbrhxpo7yipk67KeURFbw9yCuMQ==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.16-4893150192467968/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-iWYQQeY7IRzTbT1CAMfzidOwVXOkn1yFiL/UK+zk9Mvhz0EI1sZkBz9YT/HjeXwXgVCuAaq2+lf0HB43wj+GhQ==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.16-4893150192467968/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-n+qm6eFFyYKJXgOWUtEBh30Fq0qLuIxk3RCcmB7fTCNiHcvI8QvDaWD6UGriYtJdolbPG6hLDmBn3cEx32Ml2g==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.0.16-4893150192467968/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-mCUJnai4+TtYnRfp08FEvogiPZY0GyILSDt9iBhE9gcDkmO9I/ovAqmgOX7XS1ZjTa3Iw0rqu6tFyut8NMjX8w==";
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
