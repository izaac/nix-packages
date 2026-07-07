{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  libsecret,
}:
stdenv.mkDerivation rec {
  pname = "proton-drive-cli";
  version = "0.0.5";

  src = fetchurl {
    url = "https://proton.me/download/drive/cli/${version}/linux-x64/proton-drive";
    sha256 = "16rp3m5pkg1gqla2iibzzxipnygwx1vk94b5gk506gva8dbfb0j7";
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
