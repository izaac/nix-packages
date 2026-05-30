#!/usr/bin/env bash
# Bump antigravity-cli to the latest release published by Google's CLI auto-
# updater service. Each supported platform has its own manifest (version, url,
# sha512); we walk them in lockstep, refuse to write anything if upstream is
# ever mid-rollout (versions disagree across platforms), and update all four
# url+hash pairs together so the derivation can't end up half-bumped.
#
# Usage: ./update.sh [--check]
#   --check  Print current vs latest and exit non-zero if behind, no rewrite.
set -euo pipefail

DEF="$(dirname "$0")/default.nix"
CHECK_ONLY=${1:-}

BASE_URL="https://antigravity-cli-auto-updater-974169037036.us-central1.run.app/manifests"

# nix sources attr name -> manifest platform key
declare -A platforms=(
  ["x86_64-linux"]="linux_amd64"
  ["aarch64-linux"]="linux_arm64"
  ["x86_64-darwin"]="darwin_amd64"
  ["aarch64-darwin"]="darwin_arm64"
)

current=$(grep -oE 'version = "[^"]+"' "$DEF" | head -n1 | sed 's/version = "//; s/"$//')

# Fetch all manifests up front so we can fail loudly before mutating anything.
declare -A urls hashes
versions=()
for sys in "${!platforms[@]}"; do
  plat="${platforms[$sys]}"
  manifest=$(curl -fsSL "$BASE_URL/$plat.json")

  v=$(echo "$manifest" | nix shell nixpkgs#jq --command jq -r '.version')
  u=$(echo "$manifest" | nix shell nixpkgs#jq --command jq -r '.url')
  s=$(echo "$manifest" | nix shell nixpkgs#jq --command jq -r '.sha512')

  if [[ -z "$v" || -z "$u" || -z "$s" || "$v" == null ]]; then
    echo "antigravity-cli: malformed manifest for $plat" >&2
    exit 1
  fi

  versions+=("$v")
  urls[$sys]="$u"
  hashes[$sys]=$(nix --extra-experimental-features 'nix-command' hash convert --hash-algo sha512 --to sri "$s")
done

# Refuse to bump if upstream is mid-rollout with divergent per-platform versions.
new_version="${versions[0]}"
for v in "${versions[@]}"; do
  if [[ "$v" != "$new_version" ]]; then
    echo "antigravity-cli: upstream manifests disagree on version (${versions[*]}); skipping bump" >&2
    exit 1
  fi
done

if [[ "$current" == "$new_version" ]]; then
  echo "antigravity-cli already at $current"
  exit 0
fi

echo "antigravity-cli: $current -> $new_version"

if [[ "$CHECK_ONLY" == "--check" ]]; then
  exit 2
fi

# Rewrite the file with python: easier to keep the four-section edit atomic
# than juggling sed across multi-line attrs.
python3 - "$DEF" "$new_version" "${urls[x86_64-linux]}" "${hashes[x86_64-linux]}" \
                                "${urls[aarch64-linux]}" "${hashes[aarch64-linux]}" \
                                "${urls[x86_64-darwin]}" "${hashes[x86_64-darwin]}" \
                                "${urls[aarch64-darwin]}" "${hashes[aarch64-darwin]}" <<'PY'
import re
import sys

path, new_version, *rest = sys.argv[1:]
order = ["x86_64-linux", "aarch64-linux", "x86_64-darwin", "aarch64-darwin"]
entries = dict(zip(order, zip(rest[0::2], rest[1::2])))

with open(path) as f:
    text = f.read()

text = re.sub(r'version = "[^"]+";', f'version = "{new_version}";', text, count=1)

def rewrite(match):
    system = match.group(1)
    url, hash_ = entries[system]
    return (
        f'"{system}" = {{\n'
        f'      url = "{url}";\n'
        f'      hash = "{hash_}";\n'
        f'    }};'
    )

text = re.sub(
    r'"(x86_64-linux|aarch64-linux|x86_64-darwin|aarch64-darwin)" = \{\s*'
    r'url = "[^"]+";\s*'
    r'hash = "[^"]+";\s*\};',
    rewrite,
    text,
)

with open(path, "w") as f:
    f.write(text)
PY

echo "Updated antigravity-cli to $new_version across all 4 platforms"
