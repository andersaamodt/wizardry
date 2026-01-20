#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Create stub xattr helper
create_xattr_stub() {
  stub_dir=$1
  cat >"$stub_dir/xattr" <<'STUB'
#!/bin/sh
# Simple xattr stub that tracks attributes in a temp file
case "$1" in
  -w)
    # Write: xattr -w key value file
    key=$2
    value=$3
    file=$4
    attr_file="${file}.attrs"
    # Remove existing key if present
    if [ -f "$attr_file" ]; then
      grep -v "^${key}=" "$attr_file" > "${attr_file}.tmp" 2>/dev/null || true
      mv "${attr_file}.tmp" "$attr_file" 2>/dev/null || true
    fi
    # Add new key=value
    printf '%s=%s\n' "$key" "$value" >> "$attr_file"
    ;;
  -p)
    # Read: xattr -p key file
    key=$2
    file=$3
    attr_file="${file}.attrs"
    if [ -f "$attr_file" ]; then
      value=$(grep "^${key}=" "$attr_file" 2>/dev/null | cut -d= -f2-)
      if [ -n "$value" ]; then
        printf '%s\n' "$value"
        exit 0
      fi
    fi
    exit 1
    ;;
  *)
    # List: xattr file
    file=$1
    attr_file="${file}.attrs"
    if [ -f "$attr_file" ]; then
      cut -d= -f1 < "$attr_file"
    fi
    ;;
esac
STUB
  chmod +x "$stub_dir/xattr"
}

test_help() {
  run_spell "spells/mud/stats" --help
  assert_success && assert_output_contains "Usage: stats"
}

test_stats_no_avatar() {
  tmpdir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir/custom-spellbook"
  mkdir -p "$SPELLBOOK_DIR/.mud"
  # Create config with avatar disabled
  printf 'avatar=0\n' > "$SPELLBOOK_DIR/.mud/config"
  
  run_spell "spells/mud/stats"
  assert_failure && assert_error_contains "not enabled"
}

test_stats_display() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir/custom-spellbook"
  
  create_xattr_stub "$stub_dir"
  
  # Set up config with avatar enabled
  mkdir -p "$SPELLBOOK_DIR/.mud"
  printf 'avatar=1\n' > "$SPELLBOOK_DIR/.mud/config"
  
  # Create avatar
  avatar_path="$tmpdir/.avatar-test"
  mkdir -p "$avatar_path"
  printf 'avatar-path=%s\n' "$avatar_path" >> "$SPELLBOOK_DIR/.mud/config"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set some stats
  "$stub_dir/xattr" -w user.max_life 100 "$avatar_path"
  "$stub_dir/xattr" -w user.mana 50 "$avatar_path"
  "$stub_dir/xattr" -w user.kills 5 "$avatar_path"
  "$stub_dir/xattr" -w user.experience 1000 "$avatar_path"
  
  run_spell "spells/mud/stats"
  assert_success
  assert_output_contains "Stats for"
  assert_output_contains "Life:"
  assert_output_contains "Mana:"
}

test_stats_with_target() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/target.txt"
  printf 'test\n' > "$test_file"
  
  create_xattr_stub "$stub_dir"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set stats on target
  "$stub_dir/xattr" -w user.max_life 50 "$test_file"
  
  run_spell "spells/mud/stats" "$test_file"
  assert_success
  assert_output_contains "target.txt"
}

run_test_case "stats prints usage" test_help
run_test_case "stats fails when avatar not enabled" test_stats_no_avatar
run_test_case "stats displays character stats" test_stats_display
run_test_case "stats displays target stats" test_stats_with_target

finish_tests
