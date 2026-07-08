#!/bin/sh
# pd: fuzzy Proton Drive browser. Downloads selected files to current directory.
set -eu

PROTON_DRIVE="proton-drive"
CWD="$(pwd)"

# --- Preflight checks ---

if ! command -v "$PROTON_DRIVE" >/dev/null 2>&1; then
  echo "error: $PROTON_DRIVE not found in PATH" >&2
  echo "  Install proton-drive-cli or run from a shell with it available." >&2
  exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
  echo "error: fzf not found in PATH" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq not found in PATH" >&2
  exit 1
fi

if [ ! -w "$CWD" ]; then
  echo "error: current directory is not writable: $CWD" >&2
  exit 1
fi

# --- Auth check ---

check_auth() {
  test_output=$($PROTON_DRIVE filesystem list / 2>&1) || true
  case "$test_output" in
    *login*|*Login*|*auth*|*Auth*)
      echo "Not authenticated. Run:" >&2
      echo "  proton-drive auth login" >&2
      exit 1
      ;;
  esac
}

# --- Core logic ---

list_root() {
  $PROTON_DRIVE filesystem list / -j 2>&1 | jq -r '.[].path'
}

list_folder() {
  _path="$1"
  # Returns "type\tname" pairs for fzf display
  $PROTON_DRIVE filesystem list "$_path" -j 2>&1 | jq -r '.[] | "\(.type)\t\(.name.value // .name)"'
}

format_entry() {
  # Prepend icon based on type
  while IFS="$(printf '\t')" read -r type name; do
    case "$type" in
      folder) printf "📁 %s/\n" "$name" ;;
      *)      printf "📄 %s\n" "$name" ;;
    esac
  done
}

download_file() {
  _remote="$1"
  _filename=$(basename "$_remote")

  echo "⬇ Downloading: $_remote" >&2

  dl_output=$($PROTON_DRIVE filesystem download -f skip "$_remote" "$CWD" 2>&1) || {
    echo "✗ Download failed: $_remote" >&2
    echo "$dl_output" >&2
    return 1
  }

  echo "✓ Saved: $CWD/$_filename" >&2
}

upload_files() {
  _remote_dir="$1"
  _local_dir="$CWD"

  while true; do
    # Build local listing: folders prefixed with 📁, files with 📄
    entries=""
    if [ "$_local_dir" != "$CWD" ]; then
      entries="⤴ .."
    fi

    dirs=$(find "$_local_dir" -maxdepth 1 -mindepth 1 -type d -not -name '.*' -printf '%f\n' | sort)
    files=$(find "$_local_dir" -maxdepth 1 -mindepth 1 -not -type d -not -name '.*' -printf '%f\n' | sort)

    for d in $dirs; do
      entries=$(printf '%s\n📁 %s' "$entries" "$d")
    done
    for f in $files; do
      entries=$(printf '%s\n📄 %s' "$entries" "$f")
    done

    entries=$(echo "$entries" | sed '/^$/d')

    # Show relative path from CWD
    rel_path=$(echo "$_local_dir" | sed "s|^$CWD||")
    [ -z "$rel_path" ] && rel_path="."

    picks=$(echo "$entries" \
      | fzf \
          --header="⬆ Upload to: $_remote_dir | local: $rel_path | ctrl+u: upload folder" \
          --prompt="select ❯ " \
          --height=~80% \
          --multi \
          --bind="ctrl-a:select-all" \
          --expect="ctrl-u") || return 0

    # fzf --expect: first line is key pressed, rest are selections
    key=$(echo "$picks" | head -1)
    items=$(echo "$picks" | tail -n +2)

    [ -z "$items" ] && return 0

    # ctrl+u: force upload selection (even folders)
    if [ "$key" = "ctrl-u" ]; then
      echo "$items" | while IFS= read -r item; do
        [ "$item" = "⤴ .." ] && continue
        name=$(echo "$item" | sed 's/^📁 //;s/^📄 //')
        full_path="$_local_dir/$name"
        echo "⬆ Uploading: $name → $_remote_dir" >&2
        up_output=$($PROTON_DRIVE filesystem upload "$full_path" "$_remote_dir" < /dev/null 2>&1) || {
          echo "✗ Upload failed: $name" >&2
          echo "$up_output" >&2
          continue
        }
        echo "✓ Uploaded: $name" >&2
      done
      return 0
    fi

    # Enter: navigate folders, upload files
    pick_count=$(echo "$items" | wc -l)
    first_pick=$(echo "$items" | head -1)

    if [ "$pick_count" -eq 1 ]; then
      if [ "$first_pick" = "⤴ .." ]; then
        _local_dir=$(dirname "$_local_dir")
        continue
      fi
      # Single folder selected: navigate into it
      if echo "$first_pick" | grep -q '^📁 '; then
        folder_name=$(echo "$first_pick" | sed 's/^📁 //')
        _local_dir="$_local_dir/$folder_name"
        continue
      fi
    fi

    # Upload selected files (and any folders in multi-select)
    echo "$items" | while IFS= read -r item; do
      [ "$item" = "⤴ .." ] && continue
      name=$(echo "$item" | sed 's/^📁 //;s/^📄 //')
      full_path="$_local_dir/$name"
      echo "⬆ Uploading: $name → $_remote_dir" >&2
      up_output=$($PROTON_DRIVE filesystem upload "$full_path" "$_remote_dir" < /dev/null 2>&1) || {
        echo "✗ Upload failed: $name" >&2
        echo "$up_output" >&2
        continue
      }
      echo "✓ Uploaded: $name" >&2
    done
    return 0
  done
}

browse() {
  path="${1:-/}"

  while true; do
    if [ "$path" = "/" ]; then
      # Root: just show section paths
      listing=$(list_root) || {
        echo "error: failed to list root" >&2
        exit 1
      }
      choices="$listing"
    else
      # Subfolder: get typed entries
      raw=$(list_folder "$path") || {
        echo "error: failed to list '$path'" >&2
        exit 1
      }

      if [ -z "$raw" ]; then
        echo "Empty directory: $path" >&2
        path=$(dirname "$path")
        continue
      fi

      formatted=$(echo "$raw" | format_entry)

      # Prepend navigation
      choices=$(printf '⤴ ..\n%s' "$formatted")
    fi

    selections=$(echo "$choices" \
      | fzf \
          --header="📁 $path | ctrl+d: download folder | ctrl+u: upload here" \
          --prompt="❯ " \
          --height=~80% \
          --multi \
          --bind="ctrl-a:select-all" \
          --expect="ctrl-d,ctrl-u") || exit 0

    # fzf --expect: first line is key pressed, rest are selections
    key=$(echo "$selections" | head -1)
    items=$(echo "$selections" | tail -n +2)

    # ctrl+u: upload to current path
    if [ "$key" = "ctrl-u" ]; then
      upload_path="$path"
      if [ "$upload_path" = "/" ]; then
        upload_path="/my-files"
      fi
      upload_files "$upload_path"
      continue
    fi

    [ -z "$items" ] && exit 0

    # ctrl+d forces download even for folders
    force_download=false
    if [ "$key" = "ctrl-d" ]; then
      force_download=true
    fi

    echo "$items" | while IFS= read -r item; do
      # Handle ".." navigation
      if [ "$item" = "⤴ .." ]; then
        printf "NAV:%s" "$(dirname "$path")" > "$CWD/.pd_nav_$$"
        continue
      fi

      # Root paths start with /
      case "$item" in
        /*)
          printf "NAV:%s" "$item" > "$CWD/.pd_nav_$$"
          continue
          ;;
      esac

      # Strip icon prefix and determine type
      case "$item" in
        "📁 "*)
          folder=$(echo "$item" | sed 's/^📁 //; s/\/$//')
          if [ "$path" = "/" ]; then
            target="/$folder"
          else
            target="$path/$folder"
          fi

          if [ "$force_download" = "true" ]; then
            # Download entire folder
            download_file "$target" || true
            printf "DONE" > "$CWD/.pd_nav_$$"
          else
            # Navigate into folder
            printf "NAV:%s" "$target" > "$CWD/.pd_nav_$$"
          fi
          ;;
        "📄 "*)
          # File: download
          filename=$(echo "$item" | sed 's/^📄 //')
          if [ "$path" = "/" ]; then
            remote_file="/$filename"
          else
            remote_file="$path/$filename"
          fi
          download_file "$remote_file" || true
          printf "DONE" > "$CWD/.pd_nav_$$"
          ;;
        *)
          # Unknown format, try as path
          if [ "$path" = "/" ]; then
            remote_file="/$item"
          else
            remote_file="$path/$item"
          fi
          download_file "$remote_file" || true
          printf "DONE" > "$CWD/.pd_nav_$$"
          ;;
      esac
    done

    # Read navigation signal from subshell
    if [ -f "$CWD/.pd_nav_$$" ]; then
      nav_signal=$(cat "$CWD/.pd_nav_$$")
      rm -f "$CWD/.pd_nav_$$"

      case "$nav_signal" in
        NAV:*)
          path="${nav_signal#NAV:}"
          continue
          ;;
        DONE)
          exit 0
          ;;
      esac
    else
      exit 0
    fi
  done
}

# --- Cleanup trap ---

cleanup() {
  rm -f "$CWD/.pd_nav_$$"
}
trap cleanup EXIT INT TERM

# --- Entry point ---

check_auth
browse "${1:-/}"



