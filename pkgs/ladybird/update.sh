#!/usr/bin/env bash
# Update ladybird to the latest upstream commit.
# Called by the Cave-Auto-Update workflow (update.sh convention).
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEF="$DIR/default.nix"

# Fetch latest commit from main branch
NEW_REV=$(curl -sf "https://api.github.com/repos/LadybirdBrowser/ladybird/commits/main" | jq -r '.sha')
OLD_REV=$(grep -oP '(?<=rev = ")[^"]+' "$DEF")

if [[ "$NEW_REV" == "$OLD_REV" ]]; then
  echo "ladybird: already at $OLD_REV"
  exit 0
fi

echo "ladybird: $OLD_REV -> $NEW_REV"

# Update version date
COMMIT_DATE=$(curl -sf "https://api.github.com/repos/LadybirdBrowser/ladybird/commits/$NEW_REV" | jq -r '.commit.committer.date[:10]')
sed -i "s|version = \"0-unstable-[0-9-]*\"|version = \"0-unstable-${COMMIT_DATE}\"|" "$DEF"

# Update rev
sed -i "s|rev = \"$OLD_REV\"|rev = \"$NEW_REV\"|" "$DEF"

# Update source hash
NEW_SRC_HASH=$(nix-prefetch-url --unpack "https://github.com/LadybirdBrowser/ladybird/archive/${NEW_REV}.tar.gz" 2>/dev/null)
NEW_SRC_SRI=$(nix hash convert --hash-algo sha256 --to sri "$NEW_SRC_HASH")
OLD_SRC_SRI=$(grep -A2 'src = fetchFromGitHub' "$DEF" | grep -oP '(?<=hash = ")[^"]+')
sed -i "s|$OLD_SRC_SRI|$NEW_SRC_SRI|" "$DEF"

# Update cargo hash: set fake, build, capture real hash
FAKE_HASH="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
OLD_CARGO_HASH=$(grep -A2 'cargoDeps' "$DEF" | grep -oP '(?<=hash = ")[^"]+')
sed -i "s|$OLD_CARGO_HASH|$FAKE_HASH|" "$DEF"

REAL_CARGO_HASH=$(nix build --no-link ".#ladybird" 2>&1 | grep -oP '(?<=got:    )sha256-[A-Za-z0-9+/=]+' | head -1) || true
if [[ -z "$REAL_CARGO_HASH" ]]; then
  echo "::error::ladybird: failed to determine new cargoHash"
  # Restore old values so the file isn't left broken
  sed -i "s|$FAKE_HASH|$OLD_CARGO_HASH|" "$DEF"
  exit 1
fi
sed -i "s|$FAKE_HASH|$REAL_CARGO_HASH|" "$DEF"

echo "ladybird: updated to $NEW_REV ($COMMIT_DATE)"
