#!/bin/sh
# Tests for the 'last' imp

. "${0%/*}/../../test-common.sh"

test_last_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'first\nsecond\nlast\n' > "$tmpfile"
  run_spell spells/.imps/text/last "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "last"
}

test_last_handles_empty_input() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/text/last'"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "last reads from file" test_last_from_file
run_test_case "last handles empty input" test_last_handles_empty_input

finish_tests
