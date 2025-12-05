#!/bin/sh
# Tests for the 'select-input' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_select_input_stdin_mode() {
  run_cmd sh -c 'SELECT_INPUT_MODE=stdin select-input'
  assert_success
  assert_output_contains "stdin"
}

test_select_input_tty_mode() {
  run_cmd sh -c 'SELECT_INPUT_MODE=tty select-input'
  assert_success
  assert_output_contains "tty"
}

test_select_input_none_mode() {
  run_cmd sh -c 'SELECT_INPUT_MODE=none select-input'
  assert_failure
}

test_select_input_with_stdin() {
  run_cmd sh -c 'echo "input" | select-input'
  assert_success
  assert_output_contains "stdin"
}

run_test_case "select-input stdin mode" test_select_input_stdin_mode
run_test_case "select-input tty mode" test_select_input_tty_mode
run_test_case "select-input none mode fails" test_select_input_none_mode
run_test_case "select-input detects piped stdin" test_select_input_with_stdin

finish_tests
