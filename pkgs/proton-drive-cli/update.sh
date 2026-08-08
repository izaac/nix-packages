#!/usr/bin/env bash
# Bump proton-drive-cli using the official version.json endpoint.
# https://proton.me/download/drive/cli/version.json publishes the latest
# stable release with per-platform URLs and official SHA-512 checksums, so
# the hashes are taken from upstream rather than recomputed locally.
#
# Usage: ./update.sh [--check]
#   --check  Print current vs latest and exit non-zero if behind, no rewrite.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEF="${SCRIPT_DIR}/default.nix"
CHECK_ONLY="${1:-}"

VERSION_URL="https://proton.me/download/drive/cli/version.json"

# Prefer an ambient jq, fall back to nixpkgs so the script is self-contained.
if command -v jq >/dev/null 2>&1; then
  JQ=(jq)
else
  JQ=(nix shell nixpkgs#jq --command jq)
fi

if [[ ! -f "$DEF" ]]; then
  echo "proton-drive-cli: $DEF not found" >&2
  exit 1
fi

current=$(grep -oE 'version = "[^"]+"' "$DEF" | head -n1 | sed 's/version = "//; s/"$//')
if [[ -z "$current" ]]; then
  echo "proton-drive-cli: could not parse current version from $DEF" >&2
  exit 1
fi

if ! json_payload=$(curl -fsSL --retry 3 --connect-timeout 10 "$VERSION_URL"); then
  echo "proton-drive-cli: failed to fetch $VERSION_URL" >&2
  exit 1
fi

latest=$(echo "$json_payload" | "${JQ[@]}" -r '.Releases[] | select(.CategoryName == "Stable") | .Version' | head -n1)

if [[ ! "$latest" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "proton-drive-cli: invalid version received from upstream: '$latest'" >&2
  exit 1
fi

if [[ "$current" == "$latest" ]]; then
  echo "proton-drive-cli already at $current"
  exit 0
fi

echo "proton-drive-cli: $current -> $latest"

if [[ "$CHECK_ONLY" == "--check" ]]; then
  exit 2
fi

# Pull the four platform checksums upstream publishes for this release.
# shellcheck disable=SC2016 # $v is a jq variable bound via --arg, not a shell one.
read -r l_x64_hex l_arm64_hex d_arm64_hex d_x64_hex < <(
  echo "$json_payload" | "${JQ[@]}" -r --arg v "$latest" '
    [.Releases[] | select(.Version == $v) | .Files[]]
    | (map({(.Platform): .Sha512CheckSum}) | add) as $f
    | [$f["linux/x64"], $f["linux/arm64"], $f["macos/arm64"], $f["macos/x64"]]
    | @tsv
  '
)

for plat_info in "linux/x64:$l_x64_hex" "linux/arm64:$l_arm64_hex" "macos/arm64:$d_arm64_hex" "macos/x64:$d_x64_hex"; do
  plat="${plat_info%%:*}"
  hex="${plat_info#*:}"
  if [[ ! "$hex" =~ ^[0-9a-fA-F]{128}$ ]]; then
    echo "proton-drive-cli: invalid SHA-512 checksum for ${plat}: '$hex'" >&2
    exit 1
  fi
done

to_sri() {
  nix --extra-experimental-features 'nix-command' hash convert --hash-algo sha512 --to sri "$1"
}

l_x64_sri=$(to_sri "$l_x64_hex")
l_arm64_sri=$(to_sri "$l_arm64_hex")
d_arm64_sri=$(to_sri "$d_arm64_hex")
d_x64_sri=$(to_sri "$d_x64_hex")

# Rewrite the file with python: easier to keep the four-section edit atomic
# than juggling sed across multi-line attrs.
python3 - "$DEF" "$latest" "$l_x64_sri" "$l_arm64_sri" "$d_arm64_sri" "$d_x64_sri" <<'PY'
import os
import re
import sys
import tempfile

path, latest, l_x64, l_arm64, d_arm64, d_x64 = sys.argv[1:]

with open(path) as f:
    text = f.read()

text = re.sub(r'version = "[^"]+";', f'version = "{latest}";', text, count=1)

for slug, sri in (
    ("linux-x64", l_x64),
    ("linux-arm64", l_arm64),
    ("darwin-arm64", d_arm64),
    ("darwin-x64", d_x64),
):
    text, count = re.subn(
        rf'({slug}/proton-drive";\n\s*hash = ")[^"]+"',
        lambda m: f'{m.group(1)}{sri}"',
        text,
    )
    if count != 1:
        sys.exit(f"proton-drive-cli: expected 1 hash for {slug}, matched {count}")

directory = os.path.dirname(path) or "."
mode = os.stat(path).st_mode
with tempfile.NamedTemporaryFile("w", dir=directory, delete=False) as tmp:
    tmp.write(text)
    tmp_path = tmp.name
os.chmod(tmp_path, mode)
os.replace(tmp_path, path)
PY

# Guard against a rewrite that produced syntactically broken Nix.
nix-instantiate --parse "$DEF" >/dev/null

echo "Updated proton-drive-cli to ${latest} across all 4 platforms:"
echo "  linux-x64:    ${l_x64_sri}"
echo "  linux-arm64:  ${l_arm64_sri}"
echo "  darwin-arm64: ${d_arm64_sri}"
echo "  darwin-x64:   ${d_x64_sri}"
