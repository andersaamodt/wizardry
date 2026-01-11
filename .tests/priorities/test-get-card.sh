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
  
  # Get the hash from hashchant output
  # hashchant either writes to xattr and prints "File enchanted with hash: 0xXXX"
  # or prints "File hash (not enchanted): 0xXXX" followed by the hash on stdout
  if printf '%s' "$OUTPUT" | grep -q "^0x"; then
    # Hash is on stdout (when xattr not available)
    hash=$OUTPUT
  else
    # Hash is in the message, extract it
    hash=$(printf '%s' "$OUTPUT" | grep -o '0x[0-9A-F]*' | head -1)
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
