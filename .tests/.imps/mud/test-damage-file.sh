#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Create stub xattr helper

test_help() {
  run_spell "spells/.imps/mud/damage-file" --help
  assert_failure  # Imps don't have --help
}

test_damage_new_file() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test content\n' > "$test_file"
  
  stub-xattr "$stub_dir"
  
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
  
  stub-xattr "$stub_dir"
  
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
