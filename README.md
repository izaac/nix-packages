# Nix Packages

Personal Nix package collection.

## How to Update

### Rust Packages (brush-shell, ethereal-waves)
These use `buildRustPackage` and need a `cargoHash`.

1. Update `rev` and `shortRev` (if used) to latest commit.
2. Update `hash` (source hash):
   - Run: `nix shell nixpkgs#nix-prefetch-github -c nix-prefetch-github <owner> <repo> --rev <rev>`
3. Update `cargoHash`:
   - Set `cargoHash = lib.fakeHash;` (or many zeros).
   - Run: `nix-build -E 'with import <nixpkgs> {}; callPackage ./pkgs/<name>/default.nix {}'`
   - Copy "got" hash from error message into `default.nix`.
4. Verify build: `nix-build -E 'with import <nixpkgs> {}; callPackage ./pkgs/<name>/default.nix {}'`

### Other Packages (vcrunch, brave-origin)
Usually just need `rev` and `hash` updates.

1. Update `rev`.
2. Update source `hash` using `nix-prefetch-url` or `nix-prefetch-github`.
3. Verify build same as above.

## Verification
Always run `nix-build` before committing.
