#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Create stub xattr helper

test_help() {
  run_spell "spells/mud/magic-missile" --help
  assert_success && assert_output_contains "Usage: magic-missile"
}

test_missile_explicit_target() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  test_file="$tmpdir/test.txt"
  printf 'test content\n' > "$test_file"
  
  stub-xattr "$stub_dir"
  
  # Build PATH with stubs first, then wizardry imps and spells
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/fs:$PATH"
  
  run_spell "spells/mud/magic-missile" "$test_file"
  assert_success && assert_output_contains "You cast magic missile"
  assert_output_contains "damage to"
}

test_missile_random_target() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  # Create a few test files
  printf 'content1\n' > "$tmpdir/file1.txt"
  printf 'content2\n' > "$tmpdir/file2.txt"
  printf 'content3\n' > "$tmpdir/file3.txt"
  
  stub-xattr "$stub_dir"
  
  # Build PATH with stubs first, then wizardry imps and spells
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/fs:$PATH"
  
  # Use run_spell_in_dir to run in tmpdir
  run_spell_in_dir "$tmpdir" "spells/mud/magic-missile"
  assert_success && assert_output_contains "You cast magic missile"
}

test_missile_no_files() {
  tmpdir=$(make_tempdir)
  stub_dir=$(make_tempdir)
  
  stub-xattr "$stub_dir"
  
  # Build PATH with stubs first, then wizardry imps and spells
  export PATH="$stub_dir:$ROOT_DIR/spells/mud:$ROOT_DIR/spells/arcane:$ROOT_DIR/spells/enchant:$ROOT_DIR/spells/cantrips:$ROOT_DIR/spells/.imps/cond:$ROOT_DIR/spells/.imps/out:$ROOT_DIR/spells/.imps/sys:$ROOT_DIR/spells/.imps/str:$ROOT_DIR/spells/.imps/text:$ROOT_DIR/spells/.imps/paths:$ROOT_DIR/spells/.imps/fs:$PATH"
  
  # Use run_spell_in_dir to run in empty tmpdir
  run_spell_in_dir "$tmpdir" "spells/mud/magic-missile"
  assert_failure && assert_error_contains "no files found"
}

test_missile_nonexistent_target() {
  run_spell "spells/mud/magic-missile" "/nonexistent/file.txt"
  assert_failure && assert_error_contains "does not exist"
}

test_missile_directory_target() {
  tmpdir=$(make_tempdir)
  
  run_spell "spells/mud/magic-missile" "$tmpdir"
  assert_failure && assert_error_contains "must be a file"
}

run_test_case "magic-missile prints usage" test_help
run_test_case "magic-missile with explicit target" test_missile_explicit_target
run_test_case "magic-missile with random target" test_missile_random_target
run_test_case "magic-missile fails with no files" test_missile_no_files
run_test_case "magic-missile fails on nonexistent file" test_missile_nonexistent_target
run_test_case "magic-missile fails on directory" test_missile_directory_target

finish_tests
