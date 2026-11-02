{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "1.4.12";

  # Manifest URLs (for reference / update.sh):
  #   https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests/<platform>.json
  # Tarballs each contain a single `antigravity` binary at the archive root.
  sources = {
    "x86_64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.12-4768735748292608/linux-x64/cli_linux_x64.tar.gz";
      hash = "sha512-6gHHO3chh7ypKIUs+WI18NhG1tpevawYi5rnGVl0ZXN/MlVA1IPuXz9i0VECkAFxM0SXKhh937mMx7l/cgS39A==";
    };
    "aarch64-linux" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.12-4768735748292608/linux-arm/cli_linux_arm64.tar.gz";
      hash = "sha512-fK4xf7agLrOHmC8Gv7I0s2aHnPmoCtiWm1ceWlXR43pqWknNa3A8BEO7QXk3z147FKjIDLJpF6157vcjqfN0xw==";
    };
    "x86_64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.12-4768735748292608/darwin-x64/cli_mac_x64.tar.gz";
      hash = "sha512-HXg2jNWhNtxMfMcc/kZJ0bHmQ2MNeTJ/88Tv1LGakNVgPiz2WlT4DH6u+XPdCfhU2uioIotO3UxkZsZ53tm6vw==";
    };
    "aarch64-darwin" = {
      url = "https://storage.googleapis.com/antigravity-public/antigravity-cli/1.4.12-4768735748292608/darwin-arm/cli_mac_arm64.tar.gz";
      hash = "sha512-6FjPwC+1u1AKdgZD2icKzNKEeqmGt+KXPal60ZKLmdYvYrrSjAOeJbZeHKBz0nsvMLE+0JGdAyl3TrHg7ltHSA==";
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
