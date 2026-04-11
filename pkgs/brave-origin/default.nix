{
  lib,
  stdenv,
  fetchurl,
  buildPackages,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  adwaita-icon-theme,
  gsettings-desktop-schemas,
  gtk3,
  gtk4,
  qt6,
  libx11,
  libxscrnsaver,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libdrm,
  libkrb5,
  libuuid,
  libxkbcommon,
  libxshmfence,
  libgbm,
  nspr,
  nss,
  pango,
  pipewire,
  snappy,
  udev,
  wayland,
  xdg-utils,
  coreutils,
  libxcb,
  zlib,
  unzip,
  makeDesktopItem,
  commandLineArgs ? "",
  pulseSupport ? true,
  libpulseaudio,
  libGL,
  libvaSupport ? true,
  libva,
  enableVideoAcceleration ? libvaSupport,
  vulkanSupport ? false,
  addDriverRunpath,
  enableVulkan ? vulkanSupport,
}: let
  version = "1.91.33";

  deps =
    [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      gtk4
      libdrm
      libx11
      libGL
      libxkbcommon
      libxscrnsaver
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxrandr
      libxrender
      libxshmfence
      libxtst
      libuuid
      libgbm
      nspr
      nss
      pango
      pipewire
      udev
      wayland
      libxcb
      zlib
      snappy
      libkrb5
      qt6.qtbase
    ]
    ++ lib.optional pulseSupport libpulseaudio
    ++ lib.optional libvaSupport libva;

  rpath = lib.makeLibraryPath deps + ":" + lib.makeSearchPathOutput "lib" "lib64" deps;
  binpath = lib.makeBinPath deps;

  enableFeatures =
    lib.optionals enableVideoAcceleration [
      "AcceleratedVideoDecodeLinuxGL"
      "AcceleratedVideoEncoder"
    ]
    ++ lib.optional enableVulkan "Vulkan";

  disableFeatures =
    ["OutdatedBuildDetector"]
    ++ lib.optionals enableVideoAcceleration ["UseChromeOSDirectVideoDecoder"];

  desktopItem = makeDesktopItem {
    name = "brave-origin";
    desktopName = "Brave Origin";
    genericName = "Web Browser";
    exec = "brave-origin %U";
    icon = "brave-origin";
    comment = "Privacy-focused browser — Origin edition with non-essential features stripped";
    categories = ["Network" "WebBrowser"];
    mimeTypes = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    startupNotify = true;
    actions.new-window = {
      name = "New Window";
      exec = "brave-origin";
    };
    actions.new-private-window = {
      name = "New Private Window";
      exec = "brave-origin --incognito";
    };
  };
in
  stdenv.mkDerivation {
    pname = "brave-origin";
    inherit version;

    src = fetchurl {
      url = "https://github.com/brave/brave-browser/releases/download/v${version}/brave-origin-nightly-${version}-linux-amd64.zip";
      hash = "sha256-oVbU15keFGayPSGl5EzePg7g2Od2T+12a1ij4UzDdkM=";
    };

    dontConfigure = true;
    dontBuild = true;
    dontPatchELF = true;

    nativeBuildInputs = [
      unzip
      (buildPackages.wrapGAppsHook3.override {makeWrapper = buildPackages.makeShellWrapper;})
    ];

    buildInputs = [
      glib
      gsettings-desktop-schemas
      gtk3
      gtk4
      adwaita-icon-theme
    ];

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/opt/brave-origin $out/bin

      # Copy all extracted files into opt dir
      cp -r brave_resources.pak chrome_crashpad_handler chrome-management-service \
            locales resources resources.pak *.png *.so* *.dat *.bin *.json *.pak \
            brave xdg-settings xdg-mime v8_context_snapshot.bin \
            $out/opt/brave-origin/ 2>/dev/null || true

      # Catch anything we missed
      for f in *; do
        if [ -e "$f" ] && [ ! -e "$out/opt/brave-origin/$f" ]; then
          cp -r "$f" "$out/opt/brave-origin/" 2>/dev/null || true
        fi
      done

      # Patch ELF binaries
      for exe in $out/opt/brave-origin/{brave,chrome_crashpad_handler,chrome-management-service}; do
        if [ -f "$exe" ]; then
          patchelf \
            --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
            --set-rpath "${rpath}" $exe
        fi
      done

      # Replace bundled xdg utils with nix versions
      ln -sf ${xdg-utils}/bin/xdg-settings $out/opt/brave-origin/xdg-settings
      ln -sf ${xdg-utils}/bin/xdg-mime $out/opt/brave-origin/xdg-mime

      # Symlink main binary
      ln -sf $out/opt/brave-origin/brave $out/bin/brave-origin

      # Install desktop entry and icons
      install -Dm644 ${desktopItem}/share/applications/brave-origin.desktop \
        $out/share/applications/brave-origin.desktop

      for size in 32 64 128 256; do
        if [ -f "$out/opt/brave-origin/product_logo_$size.png" ]; then
          install -Dm644 "$out/opt/brave-origin/product_logo_$size.png" \
            "$out/share/icons/hicolor/''${size}x''${size}/apps/brave-origin.png"
        fi
      done

      runHook postInstall
    '';

    preFixup = ''
      gappsWrapperArgs+=(
        --prefix LD_LIBRARY_PATH : ${rpath}
        --prefix PATH : ${binpath}
        --suffix PATH : ${lib.makeBinPath [xdg-utils coreutils]}
        --set CHROME_WRAPPER brave-origin
        ${lib.optionalString (enableFeatures != []) ''
        --add-flags "--enable-features=${lib.strings.concatStringsSep "," enableFeatures}\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+,WaylandWindowDecorations --enable-wayland-ime=true}}"
      ''}
        ${lib.optionalString (disableFeatures != []) ''
        --add-flags "--disable-features=${lib.strings.concatStringsSep "," disableFeatures}"
      ''}
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto}}"
        ${lib.optionalString vulkanSupport ''
        --prefix XDG_DATA_DIRS : "${addDriverRunpath.driverLink}/share"
      ''}
        ${lib.optionalString (commandLineArgs != "") ''
        --add-flags ${lib.escapeShellArg commandLineArgs}
      ''}
      )
    '';

    meta = {
      homepage = "https://brave.com/";
      description = "Brave Origin — privacy browser with non-essential features stripped";
      license = lib.licenses.mpl20;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      mainProgram = "brave-origin";
      platforms = ["x86_64-linux"];
    };
  }
