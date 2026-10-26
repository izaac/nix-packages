{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.4.7";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.7-5900205422411776/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-vtp2BYdYn1gnsLUWw+wsW9XNLpHrDiUzgHuh6ZCifc1jrvAZHgt2+2D+qw0W6qghD7eYQsNN1ICeJX4XEu3RUg==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.7-5900205422411776/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-ap+g32MAYzQEVx9m7HkkCYzHCp8jrFXDZZE5u8vdLqUwH+Hvco1MBk+sZRBOoUordEIfMgqC5bzyGMSCtY46Fg==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.7-5900205422411776/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-l0+RBjsvXwHIlXMwTwHvsnMZrBIoofBuG46DUJsHb9y3fNUrSItyJVSqCkQ6K4rd7eXa/711pB+dUexdEIoS0Q==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.7-5900205422411776/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-AZLJkw/I7M3ceu2Wpq/ekV8p7jgMgba2qDXmjk8ZUFFNmKWWqH+6ubHYe6JJIeKTJ68GS6yM7Qu4c+eCQ4Jt6Q==";
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
