# nix-packages

Custom Nix packages for my NixOS systems.

## Packages

| Package | Description |
|---------|-------------|
| `brave-origin` | Brave Origin (Nightly) browser — binary distribution |
| `brush-shell` | Bash/POSIX-compatible shell written in Rust |
| `ethereal-waves` | COSMIC Desktop music player based on libcosmic and GStreamer |
| `vcrunch` | Video re-encoding tool with batch processing and network share support |
| `zelda-oot` | Launcher for Ship of Harkinian (Zelda: Ocarina of Time) via dwarfs + overlayfs |

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

### Run directly

```bash
nix run github:izaac/nix-packages#vcrunch
```

## Development

### Build a package locally

```bash
nix build .#<package-name>
```

### Update a package version

**Binary packages** (e.g. `brave-origin`) — only need a new source hash:

```bash
# 1. Update version in default.nix
# 2. Get the new hash (nix will tell you the correct one on mismatch):
nix build .#brave-origin
# 3. Copy the "got:" hash from the error into default.nix
# 4. Build again to verify
nix build .#brave-origin
```

**Rust/cargo packages** (e.g. `brush-shell`, `ethereal-waves`) — need both source hash and cargo vendor hash:

```bash
# 1. Update version/rev and source hash in default.nix
# 2. Set cargoHash to lib.fakeHash temporarily:
#      cargoHash = lib.fakeHash;
# 3. Build — it will fail and print the real cargoHash:
nix build .#brush-shell
# 4. Copy the "got:" hash into cargoHash
# 5. Build again to verify
nix build .#brush-shell
```

**Prefetching source hashes** (optional — you can also just let the build fail):

```bash
# For GitHub archives:
nix-prefetch-url --unpack "https://github.com/owner/repo/archive/<rev>.tar.gz"
nix hash convert --hash-algo sha256 --to sri <hash-from-above>

# For direct downloads (no unpack):
nix build .#<pkg>  # just let it fail and grab the "got:" hash
```

> **Tip:** For cargo packages, always use the `lib.fakeHash` → build → copy approach.
> Prefetching cargo vendor hashes manually is not practical.

### Run checks

```bash
nix flake check
```

## License

MIT — see [LICENSE](LICENSE).
