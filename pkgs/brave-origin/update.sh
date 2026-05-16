#!/usr/bin/env bash
# Bump brave-origin to the latest brave/brave-browser prerelease that
# actually publishes a brave-origin-nightly-*-linux-amd64.zip asset.
# Not every prerelease tag has Linux artifacts (some are Mac/Win-only),
# so we walk the assets list rather than guessing the URL.
#
# Usage: ./update.sh [--check]
#   --check  Print current vs latest and exit non-zero if behind, no rewrite.
set -euo pipefail

DEF="$(dirname "$0")/default.nix"
CHECK_ONLY=${1:-}

current=$(grep -oE 'version = "[^"]+"' "$DEF" | head -n1 | sed 's/version = "//; s/"$//')

# Walk recent prereleases, return the first one that has the linux nightly
# zip in its asset list. jq emits "<tag>\t<asset_url>" or empty on no match.
result=$(
  curl -fsSL \
       -H "Accept: application/vnd.github+json" \
       "https://api.github.com/repos/brave/brave-browser/releases?per_page=100" \
    | nix shell nixpkgs#jq --command jq -r '
        [
          .[]
          | select(.prerelease == true)
          | . as $r
          | $r.assets[]
          | select(.name | test("^brave-origin-nightly-.+-linux-amd64\\.zip$"))
          | "\($r.tag_name)\t\(.browser_download_url)"
        ] | first // empty
      '
)

if [[ -z "$result" ]]; then
  echo "No prerelease found with brave-origin-nightly-*-linux-amd64.zip asset" >&2
  exit 1
fi

new_tag="${result%%$'\t'*}"
url="${result#*$'\t'}"
new_version="${new_tag#v}"

if [[ "$current" == "$new_version" ]]; then
  echo "brave-origin already at $current"
  exit 0
fi

echo "brave-origin: $current -> $new_version"
echo "asset: $url"

if [[ "$CHECK_ONLY" == "--check" ]]; then
  exit 2
fi

new_hash=$(nix store prefetch-file --json --hash-type sha256 "$url" \
  | nix shell nixpkgs#jq --command jq -r '.hash')

if [[ -z "$new_hash" ]]; then
  echo "Failed to compute hash for $url" >&2
  exit 1
fi

sed -i -E "s|version = \"${current}\";|version = \"${new_version}\";|" "$DEF"
sed -i -E "s|hash = \"sha256-[A-Za-z0-9+/=]+\";|hash = \"${new_hash}\";|" "$DEF"

echo "Updated brave-origin: ${new_version} ${new_hash}"
