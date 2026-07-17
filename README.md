# Nix Packages

Personal Nix package collection.

## Packages

| Package            | Platforms                     | Auto-update |
|--------------------|-------------------------------|-------------|
| `proton-drive-cli` | linux, darwin (x64 + arm64)   | `update.sh` |
| `pd`               | linux, darwin                 | manual      |
| `sparrow`          | linux (x64 + arm64)           | planned     |
| `antigravity-cli`  | linux, darwin                 | nix-update  |
| `brave-origin`     | linux                         | nix-update  |
| `vcrunch`          | linux                         | manual      |
| `zelda-oot`        | linux                         | manual      |
| `flashgbx`         | linux                         | manual      |
| `opengigabyte`     | linux                         | manual      |

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
