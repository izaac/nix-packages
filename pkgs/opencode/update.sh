#!/usr/bin/env bash
# Bump opencode to the latest CLI release published in OpenCode's update
# manifest (https://opencode.ai/update/api/latest). The manifest lists the
# version plus per-platform asset names and sha256 checksums, so hashes are
# taken from upstream rather than recomputed locally. All four platform
# hashes move together so the derivation can't end up half-bumped. URLs are
# built from the version attr in default.nix, so only version + hashes move.
#
# Usage: ./update.sh [--check]
#   --check  Print current vs latest and exit non-zero if behind, no rewrite.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEF="${SCRIPT_DIR}/default.nix"
CHECK_ONLY="${1:-}"

MANIFEST_URL="https://opencode.ai/update/api/latest"

# Prefer an ambient jq, fall back to nixpkgs so the script is self-contained.
if command -v jq >/dev/null 2>&1; then
  JQ=(jq)
else
  JQ=(nix shell nixpkgs#jq --command jq)
fi

if [[ ! -f "$DEF" ]]; then
  echo "opencode: $DEF not found" >&2
  exit 1
fi

current=$(grep -oE 'version = "[^"]+"' "$DEF" | head -n1 | sed 's/version = "//; s/"$//')
if [[ -z "$current" ]]; then
  echo "opencode: could not parse current version from $DEF" >&2
  exit 1
fi

if ! json_payload=$(curl -fsSL --retry 3 --connect-timeout 10 "$MANIFEST_URL"); then
  echo "opencode: failed to fetch $MANIFEST_URL" >&2
  exit 1
fi

latest=$(echo "$json_payload" | "${JQ[@]}" -r '.artifacts[] | select(.name == "cli" and .distribution == "opencode") | .version')

if [[ ! "$latest" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "opencode: invalid version received from upstream: '$latest'" >&2
  exit 1
fi

if [[ "$current" == "$latest" ]]; then
  echo "opencode already at $current"
  exit 0
fi

echo "opencode: $current -> $latest"

if [[ "$CHECK_ONLY" == "--check" ]]; then
  exit 2
fi

# Manifest asset name for each nix sources system key.
declare -A assets=(
  ["x86_64-linux"]="opencode-linux-x64.tar.gz"
  ["aarch64-linux"]="opencode-linux-arm64.tar.gz"
  ["x86_64-darwin"]="opencode-darwin-x64.zip"
  ["aarch64-darwin"]="opencode-darwin-arm64.zip"
)

to_sri() {
  nix --extra-experimental-features 'nix-command' hash convert --hash-algo sha256 --to sri "$1"
}

declare -A hashes
for sys in "${!assets[@]}"; do
  asset="${assets[$sys]}"
  hex=$(echo "$json_payload" | "${JQ[@]}" -r --arg a "$asset" '.artifacts[] | select(.name == "cli" and .distribution == "opencode") | .metadata.files[$a].sha256')
  if [[ ! "$hex" =~ ^[0-9a-fA-F]{64}$ ]]; then
    echo "opencode: invalid sha256 for ${asset}: '$hex'" >&2
    exit 1
  fi
  hashes[$sys]=$(to_sri "$hex")
done

python3 - "$DEF" "$latest" \
  "${hashes[x86_64-linux]}" "${hashes[aarch64-linux]}" \
  "${hashes[x86_64-darwin]}" "${hashes[aarch64-darwin]}" <<'PY'
import os, re, sys, tempfile

path, latest, l_x64, l_arm64, d_x64, d_arm64 = sys.argv[1:]

with open(path) as f:
    text = f.read()

text = re.sub(r'version = "[^"]+";', f'version = "{latest}";', text, count=1)

# Only hashes move here; URLs are interpolated from the version attr.
for slug, sri in (
    ("opencode-linux-x64.tar.gz", l_x64),
    ("opencode-linux-arm64.tar.gz", l_arm64),
    ("opencode-darwin-x64.zip", d_x64),
    ("opencode-darwin-arm64.zip", d_arm64),
):
    text, count = re.subn(
        rf'({re.escape(slug)}";\s*hash = ")[^"]+"',
        lambda m: f'{m.group(1)}{sri}"',
        text,
    )
    if count != 1:
        sys.exit(f"opencode: expected 1 hash for {slug}, matched {count}")

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

echo "Updated opencode to ${latest} across all 4 platforms:"
echo "  linux-x64:    ${hashes[x86_64-linux]}"
echo "  linux-arm64:  ${hashes[aarch64-linux]}"
echo "  darwin-x64:   ${hashes[x86_64-darwin]}"
echo "  darwin-arm64: ${hashes[aarch64-darwin]}"
