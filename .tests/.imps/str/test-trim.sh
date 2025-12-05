#!/bin/sh
# Tests for the 'trim' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_trim_removes_whitespace() {
  run_cmd sh -c "printf '  hello  ' | '$ROOT_DIR/spells/.imps/str/trim'"
  assert_success
  assert_output_contains "hello"
}

test_trim_handles_empty_input() {
  run_cmd sh -c "printf '' | '$ROOT_DIR/spells/.imps/str/trim'"
  assert_success
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="output should be empty"; return 1; }
}

run_test_case "trim removes whitespace" test_trim_removes_whitespace
run_test_case "trim handles empty input" test_trim_handles_empty_input

finish_tests
