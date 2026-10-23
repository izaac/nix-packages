#!/usr/bin/env bash
# On-demand local version of .github/workflows/auto-update.yml ("Bump
# packages" step). Same package list, same per-package update.sh, same
# rollback and hash verification as CI - minus the Cachix upload, the
# git push, and the pull request. Changes land as working-tree edits;
# commit hygiene stays manual, like any local change.

# No set -e: the loop captures each tool's exit code itself and reports
# per-package failures without aborting the rest of the run.
set -uo pipefail

cd "$(dirname "$0")"

status="/tmp/nix-packages-update-status.md"
{
  echo "## Update summary"
  echo
  echo "| Package | Before | After | Status | Hash verified |"
  echo "|---------|--------|-------|--------|---------------|"
} > "$status"

packages=(brave-origin antigravity-cli opencode proton-drive-cli plex)
failures=0

for pkg in "${packages[@]}"; do
  echo "=== update $pkg ==="
  def="pkgs/$pkg/default.nix"
  before=$(grep -oE 'version = "[^"]+"' "$def" | head -n1 | sed 's/version = "//; s/"$//')

  rc=0
  if [[ -x "pkgs/$pkg/update.sh" ]]; then
    "pkgs/$pkg/update.sh" || rc=$?
  else
    nix-update --flake "$pkg" --build || rc=$?
  fi

  # A failed nightly build leaves the rewritten rev/hash in default.nix.
  # Roll it back so the tree keeps the last known-good revision instead
  # of carrying a broken bump.
  if [[ $rc -ne 0 ]]; then
    git checkout -- "$def"
    echo "warning: $pkg update failed (rc=$rc) - reverted to previous revision" >&2
  fi

  after=$(grep -oE 'version = "[^"]+"' "$def" | head -n1 | sed 's/version = "//; s/"$//')

  if [[ $rc -ne 0 ]]; then
    status_text="failed - reverted"
    failures=$((failures + 1))
  elif [[ "$before" == "$after" ]]; then
    status_text="up-to-date"
  else
    status_text="bumped"
  fi

  # Independent hash verification: build the (possibly updated) derivation
  # and let Nix compare its fixed-output hash against default.nix.
  if [[ $rc -ne 0 ]]; then
    verify="-"
  elif nix build ".#$pkg" --no-link --print-out-paths >/dev/null 2>&1; then
    verify="ok"
  else
    verify="hash mismatch"
    failures=$((failures + 1))
  fi

  printf "| %s | %s | %s | %s | %s |\n" "$pkg" "$before" "$after" "$status_text" "$verify" >> "$status"
done

echo
echo "Changed files:"
git status --short pkgs/
echo
cat "$status"

exit $((failures > 0))
