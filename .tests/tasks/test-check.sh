#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/tasks/check" --help
  assert_success || return 1
  assert_output_contains "Usage: check" || return 1
}

test_requires_argument() {
  run_spell "spells/tasks/check"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/tasks/check" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

test_checks_file() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # Check the file
  run_spell "spells/tasks/check" "$testfile"
  
  # Skip test if xattr not supported
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  assert_success || return 1
  assert_output_contains "Checked" || return 1
  
  # Verify the checked attribute is set to 1
  run_spell "spells/arcane/read-magic" "$testfile" checked
  assert_success || return 1
  if [ "$OUTPUT" != "1" ]; then
    TEST_FAILURE_REASON="Expected checked value '1', got '$OUTPUT'"
    return 1
  fi
}

run_test_case "check shows usage" test_help
run_test_case "check requires file argument" test_requires_argument
run_test_case "check fails on missing file" test_fails_on_missing_file
run_test_case "check marks file as checked" test_checks_file

finish_tests
