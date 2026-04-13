{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  libcosmicAppHook,
  just,
  pkg-config,
  glib,
  gst_all_1,
  libglvnd,
  libgbm,
}:
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "ethereal-waves";
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "cosmic-utils";
    repo = "ethereal-waves";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mDU09ut1a9rCg5rgteSbeKaaMqZwgRkSh5OS47evoYs=";
  };

  cargoHash = "sha256-eHZzcrRUPxp/G9uxJRF2e5db6ln3PVzkYjfCvKGXnZk=";

  nativeBuildInputs = [
    just
    pkg-config
    libcosmicAppHook
  ];

  buildInputs = [
    glib
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    libgbm
    libglvnd
  ];

  dontUseJustBuild = true;
  dontUseJustCheck = true;

  justFlags = [
    "--set"
    "prefix"
    (placeholder "out")
    "--set"
    "cargo-target-dir"
    "target/${stdenv.hostPlatform.rust.cargoShortTarget}"
  ];

  postInstall = ''
    # Fix icon install — just install places the SVG as a file named 'apps' instead of inside 'apps/'
    local iconDir="$out/share/icons/hicolor/scalable/apps"
    rm -f "$iconDir"
    mkdir -p "$iconDir"
    cp resources/icons/hicolor/scalable/apps/*.svg "$iconDir/"

    libcosmicAppWrapperArgs+=(--prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$GST_PLUGIN_SYSTEM_PATH_1_0")
  '';

  meta = {
    homepage = "https://github.com/cosmic-utils/ethereal-waves";
    description = "Music player for the COSMIC Desktop Environment";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "ethereal-waves";
  };
})
