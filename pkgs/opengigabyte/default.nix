{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kmod,
}:
# Out-of-tree HID kernel module for Gigabyte AERO / AORUS laptops.
#
# The keyboard sends vendor-specific "obscure" HID report codes for some Fn
# combinations (e.g. Fn+F3 / Fn+F4 brightness) that the kernel does not map,
# so no input event ever reaches userspace. This driver intercepts those raw
# reports and re-injects standard Consumer Control usages (brightness up/down),
# which then surface as the usual XF86MonBrightness keys.
#
# The brightness handler dereferences the "intel_backlight" backlight device,
# so the system must expose /sys/class/backlight/intel_backlight (ensure the
# panel uses the native i915 backlight, e.g. kernelParam acpi_backlight=native).
stdenv.mkDerivation {
  pname = "opengigabyte";
  version = "0.0.2-unstable-2026-06-24";

  src = fetchFromGitHub {
    owner = "izaac";
    repo = "opengigabyte";
    rev = "47ec3f17204467c436539c229c6d372de6a94aa7";
    hash = "sha256-qqQteE3Eg4Enef9eDPD2cNgEpSqjwXSB2Q821tK9L2A=";
  };

  # Only the kernel module under driver/ is needed; the daemon, python library
  # and udev rules ship RGB/firefly tooling that is irrelevant here.
  sourceRoot = "source/driver";

  nativeBuildInputs = kernel.moduleBuildDependencies;

  buildPhase = ''
    runHook preBuild
    make -C ${kernel.dev}/lib/modules/${kernel.modDirVersion}/build \
      M=$(pwd) modules
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -D gigabytekbd.ko \
      "$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/hid/gigabytekbd.ko"
    runHook postInstall
  '';

  nativeInstallCheckInputs = [kmod];

  meta = {
    description = "HID kernel module enabling Fn brightness keys on Gigabyte AERO/AORUS laptops";
    homepage = "https://github.com/blmhemu/opengigabyte";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
