# Nix Packages

Personal Nix package collection.

## Packages

| Package            | Platforms                     | Auto-update |
|--------------------|-------------------------------|-------------|
| `proton-drive-cli` | linux, darwin (x64 + arm64)   | `update.sh` |
| `pd`               | linux, darwin                 | manual      |
| `plex`             | linux (x64 + arm64)           | `update.sh` |
| `plex-desktop`     | linux (x64)                   | `update.sh` |
| `sparrow`          | linux (x64 + arm64)           | planned     |
| `antigravity-cli`  | linux, darwin                 | nix-update  |
| `brave-origin`     | linux                         | nix-update  |
| `vcrunch`          | linux                         | manual      |
| `zelda-oot`        | linux                         | manual      |
| `flashgbx`         | linux                         | manual      |
| `opengigabyte`     | linux                         | manual      |

`plex` tracks the newest Plex Media Server build on plex.tv, which nixpkgs
often trails by weeks. It overrides the `version` and `src` of nixpkgs'
`plexRaw` and reuses the stock FHS userenv, so `services.plex` works unchanged.
It is deliberately absent from the Cachix build list: the binaries are unfree
and redistributing them from a public cache is not ours to do.

## Usage

```bash
# Try a package without installing
nix run github:izaac/nix-packages#pd

# Use as flake input
inputs.nix-packages.url = "github:izaac/nix-packages";
```

## Updating Packages

Packages with `update.sh` scripts auto-update via the weekly GitHub Actions workflow.
For others, use `nix-update`:

```bash
nix-update --flake <package> --build
```

## Verification

```bash
nix flake check
```
