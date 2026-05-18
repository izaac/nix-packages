{
  python3Packages,
  fetchFromGitHub,
  qt6,
  copyDesktopItems,
  makeDesktopItem,
  gsettings-desktop-schemas,
  glib,
  wrapGAppsHook3,
}:
python3Packages.buildPythonApplication {
  pname = "FlashGBX";
  version = "4.6";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "lesserkuma";
    repo = "FlashGBX";
    rev = "4.6";
    hash = "sha256-t2Ssf+DBJL1ecGPNPl2Asm624D/TJ2hHHUAk61s0lzs=";
  };

  nativeBuildInputs = [
    python3Packages.setuptools
    qt6.wrapQtAppsHook
    wrapGAppsHook3
    copyDesktopItems
  ];

  buildInputs = [
    gsettings-desktop-schemas
    glib
  ];

  propagatedBuildInputs = with python3Packages; [
    pyside6
    pyserial
    pillow
    requests
    python-dateutil
    packaging
    qt6.qtwayland
    qt6.qtsvg
    qt6.qtbase
  ];

  dontWrapQtApps = true;
  dontWrapGApps = true;

  postFixup = ''
    wrapQtApp $out/bin/flashgbx "''${gappsWrapperArgs[@]}"
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "FlashGBX";
      exec = "flashgbx";
      icon = "media-flash";
      desktopName = "FlashGBX";
      genericName = "GameBoy Flasher";
      categories = ["Game"];
    })
  ];

  doCheck = false;
}
