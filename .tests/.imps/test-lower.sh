#!/bin/sh
# Tests for the 'lower' imp

. "${0%/*}/../test-common.sh"

test_lower_converts() {
  run_cmd sh -c "printf 'HELLO' | '$ROOT_DIR/spells/.imps/lower'"
  assert_success
  assert_output_contains "hello"
}

test_lower_handles_empty_input() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/lower'"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "lower converts to lowercase" test_lower_converts
run_test_case "lower handles empty input" test_lower_handles_empty_input

finish_tests
