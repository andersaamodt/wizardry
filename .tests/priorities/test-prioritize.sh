#!/bin/sh
# Test coverage for prioritize spell:
# - Shows usage with --help
# - Requires file argument
# - Fails on missing file
# - Tests echelon functionality (requires xattr support)

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/priorities/prioritize" --help
  assert_success || return 1
  assert_output_contains "Usage: prioritize" || return 1
  assert_output_contains "echelon" || return 1
}

test_requires_argument() {
  run_spell "spells/priorities/prioritize"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/priorities/prioritize" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

# Echelon tests require xattr support
test_first_priority() {
  # Check if xattr support is available
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test1.txt"
  printf 'test\n' > "$testfile"
  
  # Try to hash the file - if this fails, skip the test
  run_spell "spells/crypto/hashchant" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Prioritize first file
  run_spell "spells/priorities/prioritize" "$testfile"
  assert_success || return 1
  assert_output_contains "first priority" || return 1
  
  # Check priority value is 1
  run_spell "spells/priorities/get-priority" "$testfile"
  assert_success || return 1
  assert_output_equals "1" || return 1
}

test_echelon_promotion() {
  # Check if xattr support is available
  tmpdir=$(make_tempdir)
  file1="$tmpdir/file1.txt"
  file2="$tmpdir/file2.txt"
  printf 'content1\n' > "$file1"
  printf 'content2\n' > "$file2"
  
  # Try to hash - if this fails, skip the test
  run_spell "spells/crypto/hashchant" "$file1"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Prioritize first file
  run_spell "spells/priorities/prioritize" "$file1"
  assert_success || return 1
  
  # Prioritize second file (should be promoted to echelon 2)
  run_spell "spells/crypto/hashchant" "$file2"
  run_spell "spells/priorities/prioritize" "$file2"
  assert_success || return 1
  assert_output_contains "echelon 2" || return 1
  
  # Check file2 has priority 2
  run_spell "spells/priorities/get-priority" "$file2"
  assert_success || return 1
  assert_output_equals "2" || return 1
}

test_already_highest() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # Try to hash - if this fails, skip the test
  run_spell "spells/crypto/hashchant" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Prioritize file
  run_spell "spells/priorities/prioritize" "$testfile"
  assert_success || return 1
  
  # Prioritize again - should say already highest
  run_spell "spells/priorities/prioritize" "$testfile"
  assert_success || return 1
  assert_output_contains "already the highest priority" || return 1
}

run_test_case "prioritize shows usage text with echelon mention" test_help
run_test_case "prioritize requires file argument" test_requires_argument
run_test_case "prioritize fails on missing file" test_fails_on_missing_file
run_test_case "prioritize creates first priority" test_first_priority
run_test_case "prioritize promotes to new echelon" test_echelon_promotion
run_test_case "prioritize detects already highest" test_already_highest

finish_tests
