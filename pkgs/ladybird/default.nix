{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  fetchurl,
  unicode-emoji,
  unicode-character-database,
  unicode-idna,
  publicsuffix-list,
  cmake,
  ninja,
  perl,
  pkg-config,
  python3,
  curlFull,
  libavif,
  angle,
  libedit,
  libjxl,
  libpulseaudio,
  libwebp,
  libxcrypt,
  mimalloc,
  openssl,
  qt6Packages,
  woff2,
  cargo,
  fast-float,
  ffmpeg,
  fmt,
  fontconfig,
  rustPlatform,
  rustc,
  simdutf,
  libtommath,
  sdl3,
  icu78,
  simdjson,
  skia,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "ladybird";
  version = "0-unstable-2026-06-08";

  src = fetchFromGitHub {
    owner = "LadybirdBrowser";
    repo = "ladybird";
    rev = "8e746504167ae4ca2ca17757f872d67c8134f6c0";
    hash = "sha256-lq5hOCTGaIlw3C5aWgBiLkgDxrIUAqW4q2hS3/y/sT0=";
  };

  hstsPreload = fetchurl {
    url = "https://raw.githubusercontent.com/chromium/chromium/aa04f175415addb04bb78936b0d8b973fbd8ea61/net/http/transport_security_state_static.json";
    hash = "sha256-TKcPBRVxoZgka8M3vTV/dZ+4+f3t2+ZrZZYJl1QO4WM=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) src;
    hash = "sha256-n0ACVH8NXwe7SIaGFoJ20WIGGR3XjcuLTwPSKGJpT5s=";
  };

  postPatch = ''
    sed -i '/iconutil/d' UI/CMakeLists.txt

    perl -0pi -e \
      's/find_package\(ICU 78\.[0-9]+ EXACT REQUIRED COMPONENTS data i18n uc\)/find_package(ICU ${icu78.version} EXACT REQUIRED COMPONENTS data i18n uc)/ or die "ICU dependency not found\n"' \
      Meta/CMake/check_for_dependencies.cmake

    # Don't set absolute paths in RPATH
    substituteInPlace Meta/CMake/lagom_install_options.cmake \
      --replace-fail "\''${CMAKE_INSTALL_BINDIR}" "bin" \
      --replace-fail "\''${CMAKE_INSTALL_LIBDIR}" "lib"
  '';

  preConfigure = ''
    mkdir -p build/Caches

    cp -r ${unicode-character-database}/share/unicode build/Caches/UCD
    chmod +w build/Caches/UCD
    cp ${unicode-emoji}/share/unicode/emoji/emoji-test.txt build/Caches/UCD
    cp ${unicode-idna}/share/unicode/idna/IdnaMappingTable.txt build/Caches/UCD
    echo -n ${unicode-character-database.version} > build/Caches/UCD/version.txt
    chmod -w build/Caches/UCD

    mkdir build/Caches/PublicSuffix
    cp ${publicsuffix-list}/share/publicsuffix/public_suffix_list.dat build/Caches/PublicSuffix

    mkdir -p build/Caches/HSTSPreload
    cp ${finalAttrs.hstsPreload} build/Caches/HSTSPreload/transport_security_state_static.json
  '';

  nativeBuildInputs = [
    cargo
    cmake
    ninja
    perl
    pkg-config
    python3
    rustPlatform.cargoSetupHook
    rustc
    qt6Packages.wrapQtAppsHook
    libtommath
  ];

  buildInputs =
    [
      curlFull
      fast-float
      ffmpeg
      fmt
      fontconfig
      libavif
      angle
      libedit
      libjxl
      libwebp
      libxcrypt
      mimalloc
      openssl
      qt6Packages.qtbase
      qt6Packages.qtmultimedia
      sdl3
      simdutf
      (skia.overrideAttrs (prev: {
        gnFlags =
          prev.gnFlags
          ++ [
            "extra_cflags+=[\"-DSKCMS_API=[[gnu::visibility(\\\"default\\\")]]\"]"
          ];
        patches =
          prev.patches
          or []
          ++ [
            (fetchpatch {
              url = "https://github.com/microsoft/vcpkg/raw/64e1fbee7d9f40eab5d112aaff648c4dcffe9e47/ports/skia/skpath-enable-edit-methods.patch";
              hash = "sha256-r5+HqSjACINn8igXqBANQsq0K+fn+Ut8L2VRs40FkTM=";
            })
          ];
      }))
      woff2
      icu78
      simdjson
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      libpulseaudio.dev
      qt6Packages.qtwayland
    ];

  cmakeFlags =
    [
      (lib.cmakeBool "ENABLE_LTO_FOR_RELEASE" false)
      "-DLADYBIRD_CACHE_DIR=Caches"
      "-DENABLE_NETWORK_DOWNLOADS=OFF"
      (lib.cmakeFeature "ICU_ROOT" (toString icu78.dev))
    ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [
      "-DCMAKE_INSTALL_LIBEXECDIR=libexec"
    ];

  env.NIX_LDFLAGS = "-lGL -lfontconfig";

  dontWrapQtApps = stdenv.hostPlatform.isDarwin;

  meta = {
    description = "Ladybird — independent web browser using a novel engine";
    homepage = "https://ladybird.org";
    license = lib.licenses.bsd2;
    mainProgram = "Ladybird";
    platforms = ["x86_64-linux" "aarch64-linux"];
  };
})
