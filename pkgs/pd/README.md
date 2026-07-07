# pd: Proton Drive fuzzy downloader

Browse and download files from Proton Drive using `fzf`.

## Usage

```sh
pd              # browse from root
pd /my-files    # start in a specific folder
```

## Controls

### Remote browser

| Key       | Action                          |
|-----------|---------------------------------|
| Type      | Fuzzy filter the list           |
| Enter     | Open folder / download file     |
| Tab       | Multi-select files              |
| Ctrl+A    | Select all                      |
| Ctrl+D    | Download selected folder        |
| Ctrl+U    | Upload local files to this path |
| Esc       | Quit                            |
| ⤴ ..      | Go up one directory             |

### Upload picker (local files)

| Key       | Action                          |
|-----------|---------------------------------|
| Enter     | Open folder / upload file(s)    |
| Tab       | Multi-select                    |
| Ctrl+A    | Select all                      |
| Ctrl+U    | Upload selected folder          |
| Esc       | Cancel upload                   |
| ⤴ ..      | Go up one directory             |

Downloads to your **current working directory**.

## First-time setup

```sh
proton-drive auth login
```

Opens a browser for authentication. Session persists in your system keyring.

## Dependencies

Bundled via Nix wrapper, no manual install needed:

- `proton-drive-cli`
- `fzf`
