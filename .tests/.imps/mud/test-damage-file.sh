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
  run_spell "spells/.imps/mud/damage-file" --help
  assert_failure  # Imps don't have --help
}

test_damage_new_file() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test content\n' > "$test_file"
  
  create_xattr_stub "$stub_dir"
  
  # Build PATH with stubs first, then wizardry imps and spells
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/fs:$ROOT_DIR/spells/.imps/mud:$PATH"
  
  run_spell "spells/.imps/mud/damage-file" "$test_file" 5
  assert_success && assert_output_contains "total: 5"
}

test_damage_accumulation() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test content\n' > "$test_file"
  
  create_xattr_stub "$stub_dir"
  
  # Build PATH with stubs first, then wizardry imps and spells
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/fs:$PATH"
  
  # Apply damage first time
  run_spell "spells/.imps/mud/damage-file" "$test_file" 3
  assert_success
  
  # Apply damage second time - should accumulate
  run_spell "spells/.imps/mud/damage-file" "$test_file" 4
  assert_success && assert_output_contains "total: 7"
}

test_damage_invalid_args() {
  run_spell "spells/.imps/mud/damage-file"
  assert_failure
  
  run_spell "spells/.imps/mud/damage-file" "onlyonarg"
  assert_failure
}

test_damage_nonexistent_file() {
  run_spell "spells/.imps/mud/damage-file" "/nonexistent/file.txt" 5
  assert_failure && assert_error_contains "does not exist"
}

test_damage_invalid_number() {
  tmpdir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test content\n' > "$test_file"
  
  run_spell "spells/.imps/mud/damage-file" "$test_file" "notanumber"
  assert_failure && assert_error_contains "must be a positive number"
}

run_test_case "damage-file fails on help (no help for imps)" test_help
run_test_case "damage-file applies damage to new file" test_damage_new_file
run_test_case "damage-file accumulates damage" test_damage_accumulation
run_test_case "damage-file requires two arguments" test_damage_invalid_args
run_test_case "damage-file fails on nonexistent file" test_damage_nonexistent_file
run_test_case "damage-file rejects invalid damage number" test_damage_invalid_number

finish_tests
