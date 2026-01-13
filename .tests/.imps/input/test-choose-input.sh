#!/bin/sh
# Tests for the 'choose-input' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_choose_input_stdin_mode() {
  skip-if-compiled || return $?
  run_cmd sh -c 'CHOOSE_INPUT_MODE=stdin choose-input'
  assert_success
  assert_output_contains "stdin"
}

test_choose_input_tty_mode() {
  skip-if-compiled || return $?
  run_cmd sh -c 'CHOOSE_INPUT_MODE=tty choose-input'
  assert_success
  assert_output_contains "tty"
}

test_choose_input_none_mode() {
  skip-if-compiled || return $?
  run_cmd sh -c 'CHOOSE_INPUT_MODE=none choose-input'
  assert_failure
}

test_choose_input_with_stdin() {
  skip-if-compiled || return $?
  run_cmd sh -c 'echo "input" | choose-input'
  assert_success
  assert_output_contains "stdin"
}

run_test_case "choose-input stdin mode" test_choose_input_stdin_mode
run_test_case "choose-input tty mode" test_choose_input_tty_mode
run_test_case "choose-input none mode fails" test_choose_input_none_mode
run_test_case "choose-input detects piped stdin" test_choose_input_with_stdin

finish_tests
