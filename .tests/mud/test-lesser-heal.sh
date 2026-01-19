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
  run_spell "spells/mud/lesser-heal" --help
  assert_success && assert_output_contains "Usage: lesser-heal"
}

test_lesser_heal_self() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir/.spellbook"
  
  create_xattr_stub "$stub_dir"
  
  # Set up config
  mkdir -p "$SPELLBOOK_DIR"
  printf 'avatar-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Create avatar with damage
  avatar_path="$tmpdir/.avatar-test"
  mkdir -p "$avatar_path"
  printf 'avatar-path=%s\n' "$avatar_path" >> "$SPELLBOOK_DIR/.mud"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set stats: max_life=100, damage=30, mana=50
  "$stub_dir/xattr" -w user.max_life 100 "$avatar_path"
  "$stub_dir/xattr" -w user.damage 30 "$avatar_path"
  "$stub_dir/xattr" -w user.mana 50 "$avatar_path"
  
  run_spell "spells/mud/lesser-heal"
  assert_success
  assert_output_contains "restoring 10 HP"
  
  # Check damage was reduced
  new_damage=$("$stub_dir/xattr" -p user.damage "$avatar_path")
  [ "$new_damage" = "20" ] || fail "Expected damage=20, got $new_damage"
}

test_lesser_heal_insufficient_mana() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  export SPELLBOOK_DIR="$tmpdir/.spellbook"
  
  create_xattr_stub "$stub_dir"
  
  # Set up config
  mkdir -p "$SPELLBOOK_DIR"
  printf 'avatar-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Create avatar with low mana
  avatar_path="$tmpdir/.avatar-test"
  mkdir -p "$avatar_path"
  printf 'avatar-path=%s\n' "$avatar_path" >> "$SPELLBOOK_DIR/.mud"
  
  # Build PATH
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  # Set mana to less than cost (5)
  "$stub_dir/xattr" -w user.mana 3 "$avatar_path"
  
  run_spell "spells/mud/lesser-heal"
  assert_failure
  assert_error_contains "insufficient mana"
}

run_test_case "lesser-heal prints usage" test_help
run_test_case "lesser-heal heals self" test_lesser_heal_self
run_test_case "lesser-heal fails with insufficient mana" test_lesser_heal_insufficient_mana

finish_tests
