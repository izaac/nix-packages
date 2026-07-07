#!/usr/bin/env bash
# Bump proton-drive-cli using the official version.json endpoint.
# https://proton.me/download/drive/cli/version.json publishes the latest
# stable release with per-platform URLs and sha512 checksums.
#
# Usage: ./update.sh [--check]
#   --check  Print current vs latest and exit non-zero if behind, no rewrite.
set -euo pipefail

DEF="$(dirname "$0")/default.nix"
CHECK_ONLY=${1:-}

VERSION_URL="https://proton.me/download/drive/cli/version.json"

current=$(grep -oE 'version = "[^"]+"' "$DEF" | head -n1 | sed 's/version = "//; s/"$//')

latest=$(curl -fsSL "$VERSION_URL" \
  | nix shell nixpkgs#jq --command jq -r '.Releases[] | select(.CategoryName == "Stable") | .Version')

if [[ -z "$latest" ]]; then
  echo "Failed to parse latest version from $VERSION_URL" >&2
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

# Fetch new hashes for each platform.
x64_url="https://proton.me/download/drive/cli/${latest}/linux-x64/proton-drive"
arm64_url="https://proton.me/download/drive/cli/${latest}/linux-arm64/proton-drive"

x64_hash=$(nix-prefetch-url --type sha256 "$x64_url")
arm64_hash=$(nix-prefetch-url --type sha256 "$arm64_url")

if [[ -z "$x64_hash" || -z "$arm64_hash" ]]; then
  echo "Failed to compute hashes" >&2
  exit 1
fi

# Rewrite default.nix.
sed -i -E "s|version = \"${current}\";|version = \"${latest}\";|" "$DEF"

# Update x86_64-linux hash (first sha256 in file).
sed -i -E "0,/sha256 = \"[^\"]+\";/s|sha256 = \"[^\"]+\";|sha256 = \"${x64_hash}\";|" "$DEF"

# Update aarch64-linux hash (second sha256 in file).
sed -i -E "0,/sha256 = \"[^\"]+\";/{n; }; s|sha256 = \"[^\"]+\";|sha256 = \"${arm64_hash}\";|" "$DEF"

# Verify by re-reading — the sed above is fragile with two hashes.
# Use a more robust approach: replace by line matching the URL context.
# Rewrite from scratch if sed left things inconsistent.
x64_in_file=$(grep -A1 "linux-x64" "$DEF" | grep -oE 'sha256 = "[^"]+"' | sed 's/sha256 = "//; s/"$//')
arm64_in_file=$(grep -A1 "linux-arm64" "$DEF" | grep -oE 'sha256 = "[^"]+"' | sed 's/sha256 = "//; s/"$//')

if [[ "$x64_in_file" != "$x64_hash" || "$arm64_in_file" != "$arm64_hash" ]]; then
  echo "Sed replacement was inconsistent, doing targeted fix..." >&2
  # Use perl for reliable multi-match replacement by occurrence.
  perl -i -0pe "s{(linux-x64/proton-drive\";\n\s*sha256 = \")[^\"]+\"}{\\1${x64_hash}\"}" "$DEF"
  perl -i -0pe "s{(linux-arm64/proton-drive\";\n\s*sha256 = \")[^\"]+\"}{\\1${arm64_hash}\"}" "$DEF"
fi

echo "Updated proton-drive-cli: ${latest} (x64: ${x64_hash}, arm64: ${arm64_hash})"
