#!/bin/sh
# Tests for the 'upper' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_upper_converts() {
  run_cmd sh -c "printf 'hello' | '$ROOT_DIR/spells/.imps/str/upper'"
  assert_success
  assert_output_contains "HELLO"
}

test_upper_handles_empty_input() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/str/upper'"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "upper converts to uppercase" test_upper_converts
run_test_case "upper handles empty input" test_upper_handles_empty_input

finish_tests
