#!/bin/sh
# Tests for the 'read-line' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_read_line_from_stdin() {
  run_cmd sh -c 'echo "hello world" | SELECT_INPUT_MODE=stdin read-line'
  assert_success
  assert_output_contains "hello world"
}

test_read_line_with_prompt() {
  # Prompt goes to stderr, input from stdin
  run_cmd sh -c 'echo "response" | SELECT_INPUT_MODE=stdin read-line "Enter: "'
  assert_success
  assert_output_contains "response"
  assert_error_contains "Enter:"
}

test_read_line_empty_input() {
  run_cmd sh -c 'echo "" | SELECT_INPUT_MODE=stdin read-line'
  assert_success
}

test_read_line_no_input_fails() {
  run_cmd sh -c 'SELECT_INPUT_MODE=none read-line'
  assert_failure
}

run_test_case "read-line from stdin" test_read_line_from_stdin
run_test_case "read-line with prompt" test_read_line_with_prompt
run_test_case "read-line empty input" test_read_line_empty_input
run_test_case "read-line no input fails" test_read_line_no_input_fails

finish_tests
