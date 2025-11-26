#!/bin/sh
# Tests for the 'first' imp

. "${0%/*}/../test-common.sh"

test_first_from_file() {
  tmpfile=$(mktemp "$WIZARDRY_TMPDIR/testfile.XXXXXX")
  printf 'first\nsecond\n' > "$tmpfile"
  run_spell spells/.imps/first "$tmpfile"
  rm -f "$tmpfile"
  assert_success
  assert_output_contains "first"
}

test_first_handles_empty_input() {
  run_cmd sh -c "printf '' | $ROOT_DIR/spells/.imps/first"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "first reads from file" test_first_from_file
run_test_case "first handles empty input" test_first_handles_empty_input

finish_tests
