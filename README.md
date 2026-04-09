# nix-packages

Custom Nix packages for my NixOS systems.

## Packages

| Package | Description |
|---------|-------------|
| `vcrunch` | Video re-encoding tool with batch processing and network share support |
| `zelda-oot` | Launcher for Ship of Harkinian (Zelda: Ocarina of Time) via dwarfs + overlayfs |
| `ethereal-waves` | COSMIC Desktop music player based on libcosmic and GStreamer |

## Usage

### As a flake input

```nix
{
  inputs.nix-packages = {
    url = "github:izaac/nix-packages";
    inputs.nixpkgs.follows = "nixpkgs";
  };
}
```

Then reference packages:
```nix
nix-packages.packages.${system}.ethereal-waves
```

### Run directly

```bash
nix run github:izaac/nix-packages#vcrunch
```

## License

MIT — see [LICENSE](LICENSE).
