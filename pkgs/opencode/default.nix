{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  unzip,
  ripgrep,
  writableTmpDirAsHomeHook,
  darwin,
}: let
  version = "2.1.3";

  # update.sh rewrites these blocks in place; keep the url + hash shape it
  # greps for. Asset names come from OpenCode's update manifest.
  sources = {
    "x86_64-linux" = {
      url = "https://opencode.ai/files/bin/${version}/opencode-linux-x64.tar.gz";
      hash = "sha256-8VYaX6ckt4HZfpv4bras64K1bvkfoZwDos17JMNgKKs=";
    };
    "aarch64-linux" = {
      url = "https://opencode.ai/files/bin/${version}/opencode-linux-arm64.tar.gz";
      hash = "sha256-RLVoN059ojTwCLHrDY9gAdk6SzS4IZ86rvBY1EmcdDk=";
    };
    "x86_64-darwin" = {
      url = "https://opencode.ai/files/bin/${version}/opencode-darwin-x64.zip";
      hash = "sha256-NMkaoWlcV5PtSfQBV5EnlkAdEd3lRabhFNghXPB0V74=";
    };
    "aarch64-darwin" = {
      url = "https://opencode.ai/files/bin/${version}/opencode-darwin-arm64.zip";
      hash = "sha256-prDsV4FPdRpOorI9Gbyc2YKDIDsDLZdc6cQpqpnTYKs=";
    };
  };
in
  stdenv.mkDerivation {
    pname = "opencode";
    inherit version;

    src = fetchurl (
      sources.${stdenv.hostPlatform.system}
      or (throw "opencode: unsupported system ${stdenv.hostPlatform.system}")
    );

    # Bun standalone executable: the JS payload lives inside ELF sections, so
    # fixup stripping degrades the binary to a bare Bun runtime. Patchelf
    # (interpreter and rpath rewriting) is verified safe on this binary.
    dontStrip = true;
    dontConfigure = true;
    dontBuild = true;

    nativeBuildInputs =
      [
        makeWrapper
        writableTmpDirAsHomeHook
      ]
      ++ lib.optionals stdenv.hostPlatform.isLinux [
        autoPatchelfHook
      ]
      ++ lib.optionals stdenv.hostPlatform.isDarwin [
        unzip
        darwin.autoSignDarwinBinariesHook
      ];

    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
      stdenv.cc.cc.lib
    ];

    unpackPhase = ''
      runHook preUnpack
      ${lib.optionalString stdenv.hostPlatform.isLinux "tar -xzf $src"}
      ${lib.optionalString stdenv.hostPlatform.isDarwin "unzip -q $src"}
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 opencode $out/bin/opencode
      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/bin/opencode \
        --set OPENCODE_DISABLE_AUTOUPDATE 1 \
        --suffix PATH : ${lib.makeBinPath [ripgrep]}
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      # opencode creates $TMPDIR/opencode at startup. In the build sandbox
      # TMPDIR is the build root, which already holds the unpacked opencode
      # binary, so give the check its own scratch TMPDIR.
      tmp=$(mktemp -d)
      version_output=$(TMPDIR="$tmp" $out/bin/opencode --version)
      echo "$version_output" | grep -q "${version}"
    '';

    meta = {
      description = "AI coding agent built for the terminal";
      homepage = "https://opencode.ai";
      changelog = "https://opencode.ai/changelog";
      license = lib.licenses.mit;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      mainProgram = "opencode";
      platforms = lib.attrNames sources;
    };
  }
