#!/usr/bin/env bash
# Bump brave-origin to the latest brave/brave-browser release that
# actually publishes a brave-origin-nightly-*-linux-amd64.zip asset.
# Not every tag has Linux artifacts (some are Mac/Win-only), and brave
# promotes builds from prerelease to full release over time, so we key
# off the presence of the nightly Linux asset rather than the prerelease
# flag. Among all candidates we pick the highest semantic version and
# never move backwards.
#
# Usage: ./update.sh [--check]
#   --check  Print current vs latest and exit non-zero if behind, no rewrite.
set -euo pipefail

DEF="$(dirname "$0")/default.nix"
CHECK_ONLY=${1:-}

current=$(grep -oE 'version = "[^"]+"' "$DEF" | head -n1 | sed 's/version = "//; s/"$//')

# Collect every release carrying the linux nightly zip, regardless of the
# prerelease flag. jq emits one "<version>\t<asset_url>" line per candidate.
candidates=$(
  curl -fsSL \
       -H "Accept: application/vnd.github+json" \
       "https://api.github.com/repos/brave/brave-browser/releases?per_page=100" \
    | nix shell nixpkgs#jq --command jq -r '
        .[]
        | . as $r
        | $r.assets[]
        | select(.name | test("^brave-origin-nightly-.+-linux-amd64\\.zip$"))
        | "\($r.tag_name | ltrimstr("v"))\t\(.browser_download_url)"
      '
)

if [[ -z "$candidates" ]]; then
  echo "No release found with brave-origin-nightly-*-linux-amd64.zip asset" >&2
  exit 1
fi

# Highest semantic version wins, not whatever the API happened to list first.
new_version=$(cut -f1 <<<"$candidates" | sort -V | tail -n1)
url=$(awk -F'\t' -v v="$new_version" '$1 == v {print $2; exit}' <<<"$candidates")

# Downgrade guard: brave prunes and re-flags nightlies, so the highest
# currently-listed version can be lower than what we already ship. Only
# move forward.
highest=$(printf '%s\n%s\n' "$current" "$new_version" | sort -V | tail -n1)
if [[ "$current" == "$new_version" || "$highest" == "$current" ]]; then
  echo "brave-origin already at $current (latest listed: $new_version)"
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
