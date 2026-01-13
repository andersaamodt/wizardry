#!/bin/sh
# Test coverage for get-card spell:
# - Shows usage with --help
# - Requires hash argument
# - Finds file by hash
# - Fails when hash not found

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/priorities/get-card" --help
  assert_success || return 1
  assert_output_contains "Usage: get-card" || return 1
}

test_requires_argument() {
  run_spell "spells/priorities/get-card"
  assert_failure || return 1
  assert_error_contains "hash required" || return 1
}

test_finds_file_by_hash() {
  tmpdir=$(make_tempdir)
  
  # Create a test file and hash it
  testfile="$tmpdir/testfile.txt"
  printf 'test content\n' > "$testfile"
  
  # Hash the file
  run_spell "spells/crypto/hashchant" "$testfile"
  assert_success || return 1
  
  # Get the hash - try from xattr first, fallback to hashchant output
  run_spell "spells/arcane/read-magic" "$testfile" hash
  read_magic_exit=$?
  
  if [ $read_magic_exit -eq 0 ] && [ -n "$OUTPUT" ]; then
    # Successfully read from xattr
    hash=$OUTPUT
  else
    # xattr not available - extract hash from hashchant output
    # Output is either "File enchanted with hash: 0xABCD" or just "0xABCD"
    run_spell "spells/crypto/hashchant" "$testfile"
    hash=$(printf '%s' "$OUTPUT" | grep -o '0x[0-9A-F]*' | head -1)
  fi
  
  # Verify we got a hash
  if [ -z "$hash" ]; then
    TEST_FAILURE_REASON="Failed to extract hash from hashchant"
    return 1
  fi
  
  # Find the file by hash
  run_spell "spells/priorities/get-card" "$hash" "$tmpdir"
  assert_success || return 1
  assert_output_contains "testfile.txt" || return 1
}

test_fails_on_missing_hash() {
  tmpdir=$(make_tempdir)
  run_spell "spells/priorities/get-card" "0xNONEXISTENT" "$tmpdir"
  assert_failure || return 1
  assert_error_contains "no file found" || return 1
}

run_test_case "get-card shows usage text" test_help
run_test_case "get-card requires hash argument" test_requires_argument
run_test_case "get-card finds file by hash" test_finds_file_by_hash
run_test_case "get-card fails on missing hash" test_fails_on_missing_hash

finish_tests
