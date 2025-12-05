#!/bin/sh
# Tests for the 'read-line' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
