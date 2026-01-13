#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/priorities/deprioritize" --help
  assert_success || return 1
  assert_output_contains "Usage: deprioritize" || return 1
}

test_requires_argument() {
  run_spell "spells/priorities/deprioritize"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/priorities/deprioritize" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

test_removes_priority() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # First prioritize the file
  run_spell "spells/priorities/prioritize" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Verify it has a priority
  run_spell "spells/priorities/get-priority" "$testfile"
  assert_success || return 1
  
  # Deprioritize it
  run_spell "spells/priorities/deprioritize" "$testfile"
  assert_success || return 1
  assert_output_contains "Removed" || return 1
  
  # Verify priority is removed (get-priority should output nothing)
  run_spell "spells/priorities/get-priority" "$testfile"
  assert_success || return 1
  # Output should be empty when no priority is set
  if [ -n "$OUTPUT" ]; then
    TEST_FAILURE_REASON="Expected empty output after deprioritize, got '$OUTPUT'"
    return 1
  fi
}

run_test_case "deprioritize shows usage" test_help
run_test_case "deprioritize requires file argument" test_requires_argument
run_test_case "deprioritize fails on missing file" test_fails_on_missing_file
run_test_case "deprioritize removes priority from file" test_removes_priority

finish_tests
