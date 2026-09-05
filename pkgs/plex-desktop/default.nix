# Plex Desktop, pinned to the newest build published on Snapcraft.
#
# Upstream nixpkgs lags the newest releases; this derivation tracks the
# official Snapcraft releases directly.
#
# Bump with ./update.sh.
{
  alsa-lib,
  autoPatchelfHook,
  buildFHSEnv,
  elfutils,
  extraEnv ? {},
  fetchurl,
  ffmpeg_6-headless,
  lib,
  libdrm,
  libedit,
  libgbm,
  libpulseaudio,
  libva,
  libxkbcommon,
  libxml2_13,
  makeDesktopItem,
  makeShellWrapper,
  minizip,
  nss,
  squashfsTools,
  stdenv,
  udev,
  writeShellScript,
  xkeyboard_config,
  libxcb-wm,
  libxcb-render-util,
  libxcb-keysyms,
  libxcb-image,
  libxtst,
  libxrender,
  libxrandr,
  libxinerama,
  libxdamage,
  libxcomposite,
  xrandr,
  libxshmfence,
  pciutils,
  libdeflate,
}: let
  pname = "plex-desktop";
  version = "1.115.0";
  rev = "88";
  meta = {
    homepage = "https://plex.tv/";
    description = "Streaming media player for Plex";
    longDescription = ''
      Plex for Linux is your client for playback on the Linux
      desktop. It features the point and click interface you see in your browser
      but uses a more powerful playback engine as well as
      some other advance features.
    '';
    license = lib.licenses.unfree;
    platforms = ["x86_64-linux"];
    mainProgram = "plex-desktop";
  };
  desktopItem = makeDesktopItem {
    name = "plex-desktop";
    desktopName = "Plex";
    exec = "plex-desktop";
    icon = "plex-desktop";
    terminal = false;
    categories = ["AudioVideo"];
    startupWMClass = "Plex";
  };
  plex-desktop = stdenv.mkDerivation {
    inherit pname version meta;

    src = fetchurl {
      url = "https://api.snapcraft.io/api/v1/snaps/download/qc6MFRM433ZhI1XjVzErdHivhSOhlpf0_${rev}.snap";
      hash = "sha512-ofqr1B31aVpymFD381zlB66Dh93G9WqqRZjTPDTlG7IV90BPiPNgDSxdbci60HARP0zD6XnZa5kuqERqbupwZw==";
    };

    nativeBuildInputs = [
      autoPatchelfHook
      makeShellWrapper
      squashfsTools
    ];

    buildInputs = [
      elfutils
      ffmpeg_6-headless
      libedit
      libgbm
      libpulseaudio
      libva
      libxkbcommon
      libxml2_13
      minizip
      nss
      stdenv.cc.cc
      libxcomposite
      libxdamage
      libxinerama
      libxrandr
      libxrender
      libxtst
      libxshmfence
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-wm
      xrandr
      pciutils
      libdeflate
      udev
    ];

    strictDeps = true;

    unpackPhase = ''
      runHook preUnpack
      unsquashfs "$src"
      cd squashfs-root
      runHook postUnpack
    '';

    dontWrapQtApps = true;

    installPhase = ''
      runHook preInstall

      cp -r . $out
      # flatpak removes these during installation.
      rm -rf $out/etc $out/usr $out/lib/dri
      rm -f $out/lib/libpciaccess.so*
      rm -f $out/lib/libswresample.so*
      rm -f $out/lib/libva-*.so*
      rm -f $out/lib/libva.so*
      rm -f $out/lib/libEGL.so*
      rm -f $out/lib/libdrm.so*
      rm -f $out/lib/libdrm*

      # Keep dependencies where the version from nixpkgs is higher or bundled in snap.
      for lib in \
        libasound.so.2 \
        libdeflate.so.0 \
        libjbig.so.0 \
        libjpeg.so.8 \
        liblcms2.so.2 \
        libpci.so.3 \
        libsnappy.so.1 \
        libtiff.so.5 \
        libwebp.so.6 \
        libxkbfile.so.1 \
        libxslt.so.1
      do
        if [ -e "usr/lib/x86_64-linux-gnu/$lib" ]; then
          cp -L "usr/lib/x86_64-linux-gnu/$lib" "$out/lib/$lib"
        fi
      done

      runHook postInstall
    '';
  };
in
  buildFHSEnv {
    inherit pname version meta;
    targetPkgs = _pkgs: [
      alsa-lib
      libdrm
      udev
      xkeyboard_config
    ];

    extraInstallCommands = ''
      mkdir -p $out/share/applications $out/share/icons/hicolor/scalable/apps
      install -m 444 -D ${desktopItem}/share/applications/plex-desktop.desktop $out/share/applications/plex-desktop.desktop
      install -m 444 -D ${plex-desktop}/meta/gui/icon.png $out/share/icons/hicolor/scalable/apps/plex-desktop.png
    '';

    runScript = writeShellScript "plex-desktop.sh" ''
      # Widevine won't download unless this directory exists.
      mkdir -p $HOME/.cache/plex/

      # Copy the sqlite plugin database on first run.
      PLEX_DB="$HOME/.local/share/plex/Plex Media Server/Plug-in Support/Databases"
      if [[ ! -d "$PLEX_DB" ]]; then
        mkdir -p "$PLEX_DB"
        cp "${plex-desktop}/resources/com.plexapp.plugins.library.db" "$PLEX_DB"
      fi

      # db files should have write access.
      chmod --recursive 750 "$PLEX_DB"

      # These environment variables sometimes silently cause plex to crash.
      unset QT_QPA_PLATFORM QT_STYLE_OVERRIDE

      set -o allexport
      ${lib.toShellVars extraEnv}
      exec ${plex-desktop}/Plex.sh
    '';
    passthru.updateScript = ./update.sh;
  }
