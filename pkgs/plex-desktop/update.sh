#!/usr/bin/env bash
# Bump plex-desktop to the newest build published on Snapcraft.
#
# Usage: ./update.sh [--check]
#   --check  Print current vs latest and exit 2 if behind, without rewriting.
set -euo pipefail

DEF="$(dirname "$0")/default.nix"
CHECK_ONLY=${1:-}

API="https://api.snapcraft.io/api/v1/snaps/details/plex-desktop?channel=stable"

current=$(grep -oE 'version = "[^"]+"' "$DEF" | head -n1 | sed 's/version = "//; s/"$//')

api_json=$(curl -s -H 'X-Ubuntu-Series: 16' "$API")
new_version=$(echo "$api_json" | jq -r '.version')
revision=$(echo "$api_json" | jq -r '.revision')
download_sha512=$(echo "$api_json" | jq -r '.download_sha512')

if [[ -z "$new_version" || "$new_version" == "null" ]]; then
  echo "plex-desktop: could not read .version from $API" >&2
  exit 1
fi

if [[ "$current" == "$new_version" ]]; then
  echo "plex-desktop already at $current"
  exit 0
fi

echo "plex-desktop: $current -> $new_version (rev $revision)"

if [[ "$CHECK_ONLY" == "--check" ]]; then
  exit 2
fi

hash=$(nix-hash --to-sri --type sha512 "$download_sha512")

sed -i -E \
  -e 's/version = "[^"]+";/version = "'"${new_version}"'";/' \
  -e 's/rev = "[0-9]+";/rev = "'"${revision}"'";/' \
  -e 's|hash = "[^"]+";|hash = "'"${hash}"'";|' \
  "$DEF"

echo "Updated plex-desktop to $new_version (rev $revision)"
