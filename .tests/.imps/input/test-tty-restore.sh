#!/bin/sh
# Tests for the 'tty-save' and 'tty-restore' imps

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Note: These tests are limited because they require an actual terminal
# In CI environments without a TTY, we mainly test error handling

test_tty_restore_no_args_fails() {
  skip-if-compiled || return $?
  run_spell spells/.imps/input/tty-restore
  assert_failure
  assert_error_contains "state required"
}

test_tty_restore_empty_state_fails() {
  skip-if-compiled || return $?
  run_spell spells/.imps/input/tty-restore ""
  assert_failure
  assert_error_contains "state required"
}

run_test_case "tty-restore no args fails" test_tty_restore_no_args_fails
run_test_case "tty-restore empty state fails" test_tty_restore_empty_state_fails

finish_tests
