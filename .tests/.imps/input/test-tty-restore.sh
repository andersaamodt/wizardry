#!/bin/sh
# Tests for the 'tty-save' and 'tty-restore' imps

. "${0%/*}/../../test-common.sh"

# Note: These tests are limited because they require an actual terminal
# In CI environments without a TTY, we mainly test error handling

test_tty_restore_no_args_fails() {
  run_spell spells/.imps/input/tty-restore
  assert_failure
  assert_error_contains "state required"
}

test_tty_restore_empty_state_fails() {
  run_spell spells/.imps/input/tty-restore ""
  assert_failure
  assert_error_contains "state required"
}

run_test_case "tty-restore no args fails" test_tty_restore_no_args_fails
run_test_case "tty-restore empty state fails" test_tty_restore_empty_state_fails

finish_tests
