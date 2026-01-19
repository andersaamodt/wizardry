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
  run_spell "spells/mud/resurrect" --help
  assert_success && assert_output_contains "Usage: resurrect"
}

test_resurrect_not_dead() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir/.spellbook"
  export HOME="$tmpdir"
  
  create_xattr_stub "$stub_dir"
  
  # Set up config
  mkdir -p "$SPELLBOOK_DIR"
  printf 'avatar-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Create avatar (not dead)
  avatar_path="$tmpdir/.avatar-test"
  mkdir -p "$avatar_path"
  printf 'avatar-path=%s\n' "$avatar_path" >> "$SPELLBOOK_DIR/.mud"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  cd "$tmpdir"
  run_spell "spells/mud/resurrect"
  assert_success
  assert_output_contains "not dead"
}

test_resurrect_success() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir/.spellbook"
  export HOME="$tmpdir"
  
  create_xattr_stub "$stub_dir"
  
  # Set up config
  mkdir -p "$SPELLBOOK_DIR"
  printf 'avatar-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Create dead avatar
  avatar_path="$tmpdir/.avatar-test"
  mkdir -p "$avatar_path"
  printf 'avatar-path=%s\n' "$avatar_path" >> "$SPELLBOOK_DIR/.mud"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Mark as dead with max_life=100
  "$stub_dir/xattr" -w user.dead 1 "$avatar_path"
  "$stub_dir/xattr" -w user.max_life 100 "$avatar_path"
  
  cd "$tmpdir"
  run_spell "spells/mud/resurrect"
  assert_success
  assert_output_contains "resurrected"
  
  # Check dead flag is cleared
  dead_flag=$("$stub_dir/xattr" -p user.dead "$avatar_path" 2>/dev/null || printf '0')
  [ "$dead_flag" = "0" ] || fail "Expected dead=0, got $dead_flag"
}

test_resurrect_wrong_location() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir/.spellbook"
  export HOME="$tmpdir"
  
  create_xattr_stub "$stub_dir"
  
  # Set up config
  mkdir -p "$SPELLBOOK_DIR"
  printf 'avatar-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Create dead avatar
  avatar_path="$tmpdir/.avatar-test"
  mkdir -p "$avatar_path"
  printf 'avatar-path=%s\n' "$avatar_path" >> "$SPELLBOOK_DIR/.mud"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Mark as dead
  "$stub_dir/xattr" -w user.dead 1 "$avatar_path"
  
  # Try to resurrect from wrong directory
  other_dir=$(make_tempdir)
  cd "$other_dir"
  run_spell "spells/mud/resurrect"
  assert_failure
  assert_error_contains "home directory"
}

run_test_case "resurrect prints usage" test_help
run_test_case "resurrect succeeds when not dead" test_resurrect_not_dead
run_test_case "resurrect brings player back to life" test_resurrect_success
run_test_case "resurrect fails in wrong location" test_resurrect_wrong_location

finish_tests
