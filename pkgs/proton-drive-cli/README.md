# Proton Drive CLI - Nix Package

Unofficial Nix package for [Proton Drive CLI](https://proton.me/blog/proton-drive-cli).

## Platforms

- x86_64-linux
- aarch64-linux
- aarch64-darwin (Apple Silicon)
- x86_64-darwin (Intel Mac)

## Usage

```bash
# Authenticate (opens browser, stores session in system keyring)
proton-drive auth login

# List files
proton-drive filesystem list /my-files

# Download a file
proton-drive filesystem download /my-files/document.pdf ./

# Upload a file
proton-drive filesystem upload ./photo.jpg /my-files/photos

# JSON output (flag goes after subcommand)
proton-drive filesystem list /my-files -j
```

## Packaging Notes

The binary is a [Bun](https://bun.sh/) compiled executable. JavaScript bytecode is
appended after the ELF/Mach-O headers. Standard Nix fixup phases will destroy it:

- **`dontStrip = true`** - stripping removes the appended JS payload
- **`dontPatchELF = true`** - patching corrupts the binary layout

Without these flags the binary degrades to a plain Bun runtime (shows `bun --help`).

On Linux, the binary uses libsecret (GNOME Keyring / KDE Wallet) for credential
storage. On macOS it uses the native Keychain; no extra libraries are needed.

## Version Detection

Proton publishes version metadata at:

```
https://proton.me/download/drive/cli/version.json
```

This returns the latest release version, per-platform download URLs, and SHA-512
checksums. The `update.sh` script in this directory automates hash updates.

## Installing via Flake

```nix
{
  inputs.nix-packages.url = "github:izaac/nix-packages";

  # In your packages or environment:
  environment.systemPackages = [
    inputs.nix-packages.packages.${system}.proton-drive-cli
  ];
}
```

Or try it without installing:

```bash
nix run github:izaac/nix-packages#proton-drive-cli -- auth login
```
