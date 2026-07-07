{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  libsecret,
}: let
  version = "0.4.6";

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
      sha256 = "11ns9j7i355v15h25l2fb47xhixkdqyhfhzc33m447l1l0ql39c9";
    };
    aarch64-linux = fetchurl {
      url = "https://proton.me/download/drive/cli/${version}/linux-arm64/proton-drive";
      sha256 = "05y2l90js4vdphky7vk35pk7m9qyjs8zigwp326v5pq2j5akcbkj";
    };
  };
in
  stdenv.mkDerivation {
    pname = "proton-drive-cli";
    inherit version;

    src = srcs.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}");

    dontUnpack = true;
    dontStrip = true;
    dontPatchELF = true;

    nativeBuildInputs = [makeWrapper];

    buildInputs = [libsecret];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp $src $out/bin/proton-drive
      chmod +x $out/bin/proton-drive

      wrapProgram $out/bin/proton-drive \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [libsecret]}

      runHook postInstall
    '';

    meta = with lib; {
      description = "Proton Drive CLI";
      homepage = "https://proton.me/drive";
      license = licenses.gpl3Only;
      maintainers = [];
      platforms = ["x86_64-linux" "aarch64-linux"];
    };
  }
