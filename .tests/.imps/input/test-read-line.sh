#!/bin/sh
# Tests for the 'read-line' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_read_line_from_stdin() {
  skip-if-compiled || return $?
  run_cmd sh -c 'echo "hello world" | SELECT_INPUT_MODE=stdin read-line'
  assert_success
  assert_output_contains "hello world"
}

test_read_line_with_prompt() {
  skip-if-compiled || return $?
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
  skip-if-compiled || return $?
  run_cmd sh -c 'SELECT_INPUT_MODE=none read-line'
  assert_failure
}

run_test_case "read-line from stdin" test_read_line_from_stdin
run_test_case "read-line with prompt" test_read_line_with_prompt
run_test_case "read-line empty input" test_read_line_empty_input
run_test_case "read-line no input fails" test_read_line_no_input_fails

finish_tests
