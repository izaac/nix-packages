#!/usr/bin/env bash
# Bump plex to the newest build advertised by the plex.tv downloads API.
#
# Plex ships a single version across every platform in a given release, so the
# two Debian archives nixpkgs' plexRaw consumes (amd64, arm64) always move
# together. Both url+hash pairs are rewritten in one pass so the derivation
# can never end up half-bumped.
#
# Usage: ./update.sh [--check]
#   --check  Print current vs latest and exit 2 if behind, without rewriting.
set -euo pipefail

DEF="$(dirname "$0")/default.nix"
CHECK_ONLY=${1:-}

API="https://plex.tv/api/downloads/5.json"

# nix attribute name -> Debian architecture suffix in the archive filename
declare -A arches=(
  ["x86_64-linux"]="amd64"
  ["aarch64-linux"]="arm64"
)

current=$(grep -oE 'version = "[^"]+"' "$DEF" | head -n1 | sed 's/version = "//; s/"$//')

api_json=$(nix shell nixpkgs#curl --command curl -fsSL "$API")
new_version=$(echo "$api_json" | nix shell nixpkgs#jq --command jq -r '.computer.Linux.version')

if [[ -z "$new_version" || "$new_version" == "null" ]]; then
  echo "plex: could not read .computer.Linux.version from $API" >&2
  exit 1
fi

if [[ "$current" == "$new_version" ]]; then
  echo "plex already at $current"
  exit 0
fi

echo "plex: $current -> $new_version"

if [[ "$CHECK_ONLY" == "--check" ]]; then
  exit 2
fi

# Fetch every archive before touching the file so a mid-rollout 404 on one
# architecture cannot leave the other one bumped.
declare -A hashes
for sys in "${!arches[@]}"; do
  arch="${arches[$sys]}"
  url="https://downloads.plex.tv/plex-media-server-new/${new_version}/debian/plexmediaserver_${new_version}_${arch}.deb"

  base32=$(nix-prefetch-url --type sha256 "$url" 2>/dev/null | tail -n1)
  if [[ -z "$base32" ]]; then
    echo "plex: failed to prefetch $url" >&2
    exit 1
  fi

  hashes[$sys]=$(nix --extra-experimental-features 'nix-command' hash convert \
    --hash-algo sha256 --to sri "$base32")
done

python3 - "$DEF" "$new_version" \
  "${hashes[x86_64-linux]}" \
  "${hashes[aarch64-linux]}" <<'PY'
import re
import sys

path, new_version, amd64_hash, arm64_hash = sys.argv[1:]
entries = {"amd64": amd64_hash, "arm64": arm64_hash}

with open(path) as f:
    text = f.read()

text = re.sub(r'version = "[^"]+";', f'version = "{new_version}";', text, count=1)


def rewrite(match):
    arch = match.group(1)
    return f'_{arch}.deb";\n      hash = "{entries[arch]}";'


text, count = re.subn(
    r'_(amd64|arm64)\.deb";\s*hash = "[^"]+";',
    rewrite,
    text,
)

if count != len(entries):
    sys.exit(f"plex: expected {len(entries)} hash entries, rewrote {count}")

with open(path, "w") as f:
    f.write(text)
PY

echo "Updated plex to $new_version (amd64 + arm64)"
