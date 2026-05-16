#!/usr/bin/env bash
# Bump brave-origin to the latest nightly release published on
# brave/brave-browser GitHub. brave-origin assets ship as part of
# brave's nightly tagged releases (prerelease: true).
#
# Usage: ./update.sh [--check]
#   --check  Print current vs latest and exit non-zero if behind, no rewrite.
set -euo pipefail

DEF="$(dirname "$0")/default.nix"
CHECK_ONLY=${1:-}

# Resolve current version pinned in default.nix
current=$(grep -oE 'version = "[^"]+"' "$DEF" | head -n1 | sed 's/version = "//; s/"$//')

# Latest prerelease tag from brave/brave-browser. The API returns releases
# in publish-date order (newest first); filter prereleases and take the head.
latest_tag=$(
  curl -fsSL \
       -H "Accept: application/vnd.github+json" \
       "https://api.github.com/repos/brave/brave-browser/releases?per_page=30" \
    | nix shell nixpkgs#jq --command jq -r \
        '[.[] | select(.prerelease == true)] | .[0].tag_name'
)

new_version="${latest_tag#v}"

if [[ -z "$new_version" || "$new_version" == "null" ]]; then
  echo "Failed to resolve latest nightly tag from GitHub API" >&2
  exit 1
fi

if [[ "$current" == "$new_version" ]]; then
  echo "brave-origin already at $current"
  exit 0
fi

echo "brave-origin: $current -> $new_version"

if [[ "$CHECK_ONLY" == "--check" ]]; then
  exit 2
fi

url="https://github.com/brave/brave-browser/releases/download/v${new_version}/brave-origin-nightly-${new_version}-linux-amd64.zip"

# Prefetch the new asset and capture its SRI hash. nix store prefetch-file
# downloads to the store and emits the canonical sha256 in SRI form.
new_hash=$(nix store prefetch-file --json --hash-type sha256 "$url" \
  | nix shell nixpkgs#jq --command jq -r '.hash')

if [[ -z "$new_hash" ]]; then
  echo "Failed to compute hash for $url" >&2
  exit 1
fi

# Rewrite default.nix in place. Both edits are anchored on full lines so
# we don't accidentally touch deps that also have a `version = ...` field.
sed -i -E "s|version = \"${current}\";|version = \"${new_version}\";|" "$DEF"
sed -i -E "s|hash = \"sha256-[A-Za-z0-9+/=]+\";|hash = \"${new_hash}\";|" "$DEF"

echo "Updated brave-origin: ${new_version} ${new_hash}"
