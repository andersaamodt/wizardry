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
  _run_cmd sh -c 'echo "hello world" | SELECT_INPUT_MODE=stdin read-line'
  _assert_success
  _assert_output_contains "hello world"
}

test_read_line_with_prompt() {
  # Prompt goes to stderr, input from stdin
  _run_cmd sh -c 'echo "response" | SELECT_INPUT_MODE=stdin read-line "Enter: "'
  _assert_success
  _assert_output_contains "response"
  _assert_error_contains "Enter:"
}

test_read_line_empty_input() {
  _run_cmd sh -c 'echo "" | SELECT_INPUT_MODE=stdin read-line'
  _assert_success
}

test_read_line_no_input_fails() {
  _run_cmd sh -c 'SELECT_INPUT_MODE=none read-line'
  _assert_failure
}

_run_test_case "read-line from stdin" test_read_line_from_stdin
_run_test_case "read-line with prompt" test_read_line_with_prompt
_run_test_case "read-line empty input" test_read_line_empty_input
_run_test_case "read-line no input fails" test_read_line_no_input_fails

_finish_tests
