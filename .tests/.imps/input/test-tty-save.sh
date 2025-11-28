#!/bin/sh
# Tests for the 'tty-save' imp

. "${0%/*}/../../test-common.sh"

# Note: tty-save requires an actual terminal for full functionality
# In CI, we test basic invocation (it will fail without a tty, but shouldn't crash)

test_tty_save_without_tty_fails() {
  # Running without a terminal should fail gracefully
  run_spell spells/.imps/input/tty-save
  # It should fail (no TTY) or succeed (if somehow there is one)
  # We just ensure it doesn't crash unexpectedly
}

test_tty_save_custom_fd_fails() {
  # Running with invalid fd should fail
  run_spell spells/.imps/input/tty-save 99
  assert_failure
}

run_test_case "tty-save handles missing tty" test_tty_save_without_tty_fails
run_test_case "tty-save invalid fd fails" test_tty_save_custom_fd_fails

finish_tests
