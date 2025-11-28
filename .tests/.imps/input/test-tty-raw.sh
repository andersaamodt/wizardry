#!/bin/sh
# Tests for the 'tty-raw' imp

. "${0%/*}/../../test-common.sh"

# Note: tty-raw requires an actual terminal for full functionality
# In CI, we test basic invocation (it will fail without a tty, but shouldn't crash)

test_tty_raw_without_tty_fails() {
  # Running without a terminal should fail gracefully
  run_spell spells/.imps/input/tty-raw
  # It should fail (no TTY in sandbox environment)
  assert_failure
}

test_tty_raw_custom_fd_fails() {
  # Running with invalid fd should fail
  run_spell spells/.imps/input/tty-raw 99
  assert_failure
}

run_test_case "tty-raw fails without tty" test_tty_raw_without_tty_fails
run_test_case "tty-raw invalid fd fails" test_tty_raw_custom_fd_fails

finish_tests
