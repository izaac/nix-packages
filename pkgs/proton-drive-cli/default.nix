{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  libsecret,
}: let
  version = "0.7.0";

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
      hash = "sha512-Wlr/y+wE6pJqMtEOI2wTQiJ/G21BbLeX+I+UOyxPHc9TtYl6EV8cGqnOjOkv1jfhxQvSI7BIZld2gfBYTszbxg==";
    };
    aarch64-linux = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/linux-arm64/proton-drive";
      hash = "sha512-c8aAFxcbV/ThEmsUd90Smo2OcYn+QjhxRfzLSAijrB2jIO8Q2DdUNkcG3oDsxwDdjgQyHw1gwgLiDVRvkwTvww==";
    };
    aarch64-darwin = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/darwin-arm64/proton-drive";
      hash = "sha512-e1/0/1nn0WSmKYpiObjS97H/seupTlPek6Y367EMYtEAYywo6sFE5yJ1XChFT+kze5zD9dCcmW4X7tmgeZLS7Q==";
    };
    x86_64-darwin = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/darwin-x64/proton-drive";
      hash = "sha512-FGu65y4KbZtp/ohxERW1f8LnAEHUFWwEooCEUDPsLRlr2v6ziOKJjbXfn8uJB+h4x/eSDP5EgwfvDL01mRMzjw==";
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
