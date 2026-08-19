{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  libsecret,
}: let
  version = "0.8.0";

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
      hash = "sha512-z2HCaIxF4QVdit1iIdlHGlpbZL87zbhkYPXLGEFFlsxN8822YnyQl8lL7DKjyZFa2jIR7yrlvjPEbrvJlsyqKA==";
    };
    aarch64-linux = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/linux-arm64/proton-drive";
      hash = "sha512-J6GuwdIJX9ShqB4dR80fn9SQG9V5/+UDQtFeLlIHjW6LLd3PWKSjhkONx1YgF3eL4mwbpiOZ+QGugsdDDiFAow==";
    };
    aarch64-darwin = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/darwin-arm64/proton-drive";
      hash = "sha512-FIOi+mr+ekmr3DT2ZCC4fgpdSNI29vSnnq5/fXbcOmvuvtzeXiKc5f3vQkUK2kG7zAIWGmSvtHO8qk/ak4xzKQ==";
    };
    x86_64-darwin = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/darwin-x64/proton-drive";
      hash = "sha512-T+2Tmr+6tKepbiqvFk1nLOPixswHF+ZbGMMcql9Szmbjq4Q+wvPEUaMmizgpHNlkYyqKv2ycjsN/VCiXMQbJ3Q==";
    };
  };

  isLinux = stdenv.hostPlatform.isLinux;
in
  stdenv.mkDerivation {
    pname = "proton-drive-cli";
    inherit version;

    src = srcs.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}");

    dontUnpack = true;
    dontStrip = true;
    dontPatchELF = true;

    nativeBuildInputs = [makeWrapper];

    buildInputs = lib.optionals isLinux [libsecret];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp $src $out/bin/proton-drive
      chmod +x $out/bin/proton-drive

      ${
        if isLinux
        then ''
          wrapProgram $out/bin/proton-drive \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libsecret]}
        ''
        else ""
      }

      runHook postInstall
    '';

    meta = with lib; {
      description = "Proton Drive CLI";
      homepage = "https://proton.me/drive";
      license = licenses.gpl3Only;
      maintainers = [];
      platforms = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
    };
  }
