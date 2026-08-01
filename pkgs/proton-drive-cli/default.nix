{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  libsecret,
}: let
  version = "0.6.0";

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
      sha256 = "04i0l3hcznd1vk6zaw56jsljcarxqrwmxl2wiz8y5xcwpxiqf9hc";
    };
    aarch64-linux = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/linux-arm64/proton-drive";
      sha256 = "03dgrxd840905bg7c6d4ng55pz5w42fa37jnxy8varzz3ykp9dss";
    };
    aarch64-darwin = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/darwin-arm64/proton-drive";
      sha256 = "1c70ag62296qpxl4cjcx69pg9sq1gz3m4m7dkidz9g8xpcv9fsk0";
    };
    x86_64-darwin = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/darwin-x64/proton-drive";
      sha256 = "0frcm2hcb7gw55jcj66gqzbi77gy0iijbz7f7hn9xrmx0bq6cahg";
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
