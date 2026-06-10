{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  libsecret,
}:
stdenv.mkDerivation rec {
  pname = "proton-drive-cli";
  version = "0.0.3";

  src = fetchurl {
    url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
    sha256 = "0wzjixykbfgz0fykzxnqqmv5yg63ns6iz3vs8jazh6lw3qslv6wn";
  };

  dontUnpack = true;

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
    platforms = ["x86_64-linux"];
  };
}
