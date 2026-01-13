#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/tasks/uncheck" --help
  assert_success || return 1
  assert_output_contains "Usage: uncheck" || return 1
}

test_requires_argument() {
  run_spell "spells/tasks/uncheck"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/tasks/uncheck" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

test_unchecks_file() {
  tmpdir=$(make_tempdir)
  testfile="$tmpdir/test.txt"
  printf 'test\n' > "$testfile"
  
  # First check the file
  run_spell "spells/tasks/check" "$testfile"
  if [ "$STATUS" -ne 0 ]; then
    echo "SKIP: xattr support not available"
    return 0
  fi
  
  # Then uncheck it
  run_spell "spells/tasks/uncheck" "$testfile"
  assert_success || return 1
  assert_output_contains "Unchecked" || return 1
  
  # Verify the checked attribute is set to 0
  run_spell "spells/arcane/read-magic" "$testfile" checked
  assert_success || return 1
  if [ "$OUTPUT" != "0" ]; then
    TEST_FAILURE_REASON="Expected checked value '0', got '$OUTPUT'"
    return 1
  fi
}

run_test_case "uncheck shows usage" test_help
run_test_case "uncheck requires file argument" test_requires_argument
run_test_case "uncheck fails on missing file" test_fails_on_missing_file
run_test_case "uncheck marks file as unchecked" test_unchecks_file

finish_tests
