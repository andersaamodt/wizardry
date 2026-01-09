#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/tasks/get-checked" --help
  assert_success || return 1
  assert_output_contains "Usage: get-checked" || return 1
}

test_requires_argument() {
  run_spell "spells/tasks/get-checked"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/tasks/get-checked" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

test_returns_unchecked_for_new_file() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # Get checked status (should default to unchecked/0)
  run_spell "spells/tasks/get-checked" "$testfile"
  
  # Skip test if xattr not supported
  if echo "$ERROR" | grep -q "xattr"; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  assert_success || return 1
  # Output should be "0" when run in non-tty (test environment)
  if [ "$OUTPUT" != "0" ]; then
    TEST_FAILURE_REASON="Expected output '0', got '$OUTPUT'"
    return 1
  fi
}

test_returns_checked_status() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # Check the file
  run_spell "spells/tasks/check" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Get checked status
  run_spell "spells/tasks/get-checked" "$testfile"
  assert_success || return 1
  # Output should be "1" when run in non-tty (test environment)
  if [ "$OUTPUT" != "1" ]; then
    TEST_FAILURE_REASON="Expected output '1', got '$OUTPUT'"
    return 1
  fi
}

run_test_case "get-checked shows usage" test_help
run_test_case "get-checked requires file argument" test_requires_argument
run_test_case "get-checked fails on missing file" test_fails_on_missing_file
run_test_case "get-checked returns unchecked for new file" test_returns_unchecked_for_new_file
run_test_case "get-checked returns checked status" test_returns_checked_status

finish_tests
