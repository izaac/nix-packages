# Plex Media Server, pinned to the newest build published on plex.tv.
#
# nixpkgs (both stable and unstable) lags the upstream release by weeks, which
# is a problem when a release carries server-side security fixes. Rather than
# vendoring the whole derivation, this overrides the `version` and `src` of
# nixpkgs' `plexRaw` and feeds the result back into the stock FHS userenv, so
# the install layout, the base database handling and the NixOS module contract
# all stay exactly as upstream nixpkgs defines them.
#
# Bump with ./update.sh, which reads https://plex.tv/api/downloads/5.json.
{
  lib,
  stdenv,
  fetchurl,
  plex,
  plexRaw,
}: let
  version = "1.43.5.11079-b3b13e506";

  # Debian packages, matching the archives nixpkgs' plexRaw consumes.
  sources = {
    x86_64-linux = {
      url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_amd64.deb";
      hash = "sha256-dOmnHJfgbW6SXMQ5gnkUH9g47p30RvkOdpYU+iyHogY=";
    };
    aarch64-linux = {
      url = "https://downloads.plex.tv/plex-media-server-new/${version}/debian/plexmediaserver_${version}_arm64.deb";
      hash = "sha256-ivNrF/iG40QUCotH5OLvZT8xx4bS6qc4dEL1tgYgBxc=";
    };
  };

  inherit (stdenv.hostPlatform) system;

  source =
    sources.${system}
    or (throw "plex: unsupported system ${system}; expected one of ${lib.concatStringsSep ", " (lib.attrNames sources)}");

  raw = plexRaw.overrideAttrs (_: {
    inherit version;
    src = fetchurl source;

    # Upstream's updateScript rewrites the nixpkgs attribute, not this one.
    passthru = {};
  });
in
  (plex.override {plexRaw = raw;}).overrideAttrs (old: {
    passthru =
      (old.passthru or {})
      // {
        inherit version;
        plexRaw = raw;
        updateScript = ./update.sh;
      };
  })
