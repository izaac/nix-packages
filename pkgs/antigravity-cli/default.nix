{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.2.2";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-dDQs8qeLNEOS5XO2OKZIpq0fjod/SUuW4g+cK3kVjVxCPECy3PeIcDNiuwqRUPCccH/eWZ11V84BwSIIgCpjyw==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-oWRaMPNrdnx1NML2pT6Zqb+t6ZMmfvzKcV96RdeX1H1lYd94fp1KUaO9/JvoVdSdI/o/S5GyxmH9FzFAUINgSA==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-s6Yao/B7/83COygWVz6dKZ04/AKJAPS1BSVxPacykzp8ZmuqZi5sjnzmTDnd/mxOo7VHXeY+isFEzSHieH2fDQ==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.2.2-6061403484848128/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-ijte3qUeEHp0QTzqXu0cWwLe3pRbohx2JbfIb0d8LIrEI1gd4O2E/y+Xw79oGMH8JMqEz5p2wvsCpQ6J2KDSmg==";
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
