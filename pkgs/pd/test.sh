#!/usr/bin/env bash
# Unit tests for pd using mocked proton-drive binary.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR=$(mktemp -d)
MOCK_BIN="$TEST_DIR/bin"
# Real system PATH for jq, sed, grep etc. Mocks override specific binaries.
REAL_PATH="$PATH"
mkdir -p "$MOCK_BIN"

cleanup() { rm -rf "$TEST_DIR"; }
trap cleanup EXIT

PASS=0
FAIL=0

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  ✓ $desc"
    ((PASS++))
  else
    echo "  ✗ $desc"
    echo "    expected to contain: $needle"
    echo "    got: $haystack"
    ((FAIL++))
  fi
}

reset_mocks() {
  rm -rf "$MOCK_BIN"
  mkdir -p "$MOCK_BIN"
}

# --- Test: missing proton-drive ---

echo "Test: preflight - missing proton-drive"
# Remove proton-drive from PATH by creating an empty overlay
EMPTY_DIR="$TEST_DIR/empty"
mkdir -p "$EMPTY_DIR"
# Symlink everything except proton-drive, fzf stays available
output=$(PATH="$EMPTY_DIR" bash "$SCRIPT_DIR/pd.sh" 2>&1) || true
assert_contains "reports missing binary" "not found" "$output"

# --- Test: not authenticated ---

echo "Test: auth check - not logged in"
reset_mocks
cat > "$MOCK_BIN/proton-drive" << 'EOF'
#!/usr/bin/env bash
echo "You need to login first"
exit 1
EOF
chmod +x "$MOCK_BIN/proton-drive"

output=$(cd "$TEST_DIR" && PATH="$MOCK_BIN:$REAL_PATH" bash "$SCRIPT_DIR/pd.sh" 2>&1) || true
assert_contains "tells user to login" "proton-drive auth login" "$output"

# --- Test: non-writable directory ---

echo "Test: preflight - non-writable cwd"
reset_mocks
cat > "$MOCK_BIN/proton-drive" << 'EOF'
#!/usr/bin/env bash
echo '[{"path":"/my-files"}]'
EOF
chmod +x "$MOCK_BIN/proton-drive"

NO_WRITE="$TEST_DIR/no-write"
mkdir -p "$NO_WRITE"
chmod 555 "$NO_WRITE"
output=$(cd "$NO_WRITE" && PATH="$MOCK_BIN:$REAL_PATH" bash "$SCRIPT_DIR/pd.sh" 2>&1) || true
assert_contains "reports not writable" "not writable" "$output"
chmod 755 "$NO_WRITE"

# --- Test: successful file download ---

echo "Test: download flow - file selected"
reset_mocks

cat > "$MOCK_BIN/proton-drive" << 'EOF'
#!/usr/bin/env bash
case "$1 $2" in
  "filesystem list")
    case "${*}" in
      *"/"*"-j"*|*"-j"*"/"*)
        echo '[{"path":"/my-files"}]'
        ;;
      *"/my-files"*)
        echo '[{"type":"file","name":{"ok":true,"value":"notes.txt"}},{"type":"folder","name":{"ok":true,"value":"docs"}}]'
        ;;
    esac
    ;;
  "filesystem download")
    echo "Downloaded"
    ;;
esac
EOF
chmod +x "$MOCK_BIN/proton-drive"

FZF_COUNT_FILE="$TEST_DIR/fzf_count"
echo "0" > "$FZF_COUNT_FILE"

cat > "$MOCK_BIN/fzf" << EOF
#!/usr/bin/env bash
count=\$(cat "$FZF_COUNT_FILE")
count=\$((count + 1))
echo "\$count" > "$FZF_COUNT_FILE"

echo ""
if [ \$count -eq 1 ]; then
  echo "/my-files"
else
  echo "📄 notes.txt"
fi
EOF
chmod +x "$MOCK_BIN/fzf"

output=$(cd "$TEST_DIR" && PATH="$MOCK_BIN:$REAL_PATH" bash "$SCRIPT_DIR/pd.sh" 2>&1) || true
assert_contains "shows download message" "Downloading" "$output"
assert_contains "shows success" "✓" "$output"

# --- Test: folder navigation then download ---

echo "Test: navigation - entering folder"
reset_mocks

CALL_COUNT_FILE="$TEST_DIR/pd_call_count"
echo "0" > "$CALL_COUNT_FILE"

cat > "$MOCK_BIN/proton-drive" << EOF
#!/usr/bin/env bash
count=\$(cat "$CALL_COUNT_FILE")
count=\$((count + 1))
echo "\$count" > "$CALL_COUNT_FILE"

case "\$1 \$2" in
  "filesystem list")
    case "\${*}" in
      *"/documents"*)
        echo '[{"type":"file","name":{"ok":true,"value":"report.pdf"}}]'
        ;;
      *"/my-files"*)
        echo '[{"type":"folder","name":{"ok":true,"value":"documents"}},{"type":"file","name":{"ok":true,"value":"photo.jpg"}}]'
        ;;
      *)
        echo '[{"path":"/my-files"}]'
        ;;
    esac
    ;;
  "filesystem download")
    echo "Downloaded"
    ;;
esac
EOF
chmod +x "$MOCK_BIN/proton-drive"

FZF_COUNT_FILE="$TEST_DIR/fzf_count2"
echo "0" > "$FZF_COUNT_FILE"

cat > "$MOCK_BIN/fzf" << EOF
#!/usr/bin/env bash
count=\$(cat "$FZF_COUNT_FILE")
count=\$((count + 1))
echo "\$count" > "$FZF_COUNT_FILE"

echo ""
if [ \$count -eq 1 ]; then
  echo "/my-files"
elif [ \$count -eq 2 ]; then
  echo "📁 documents/"
else
  echo "📄 report.pdf"
fi
EOF
chmod +x "$MOCK_BIN/fzf"

output=$(cd "$TEST_DIR" && PATH="$MOCK_BIN:$REAL_PATH" bash "$SCRIPT_DIR/pd.sh" 2>&1) || true
assert_contains "downloads from subfolder" "report.pdf" "$output"

# --- Summary ---

echo
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
