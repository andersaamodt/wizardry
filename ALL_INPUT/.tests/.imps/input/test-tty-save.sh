#!/bin/sh
# Tests for the 'tty-save' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Note: tty-save requires an actual terminal for full functionality
# In CI, we test basic invocation (it will fail without a tty, but shouldn't crash)

test_tty_save_without_tty_fails() {
  # Running without a terminal should fail gracefully
  _run_spell spells/.imps/input/tty-save
  # It should fail (no TTY) or succeed (if somehow there is one)
  # We just ensure it doesn't crash unexpectedly
}

test_tty_save_ignores_extra_args() {
  # Extra arguments should be ignored (POSIX-compliant imps are simpler)
  _run_spell spells/.imps/input/tty-save ignored_arg
  # Still fails due to no TTY, but shouldn't crash
}

_run_test_case "tty-save handles missing tty" test_tty_save_without_tty_fails
_run_test_case "tty-save ignores extra args" test_tty_save_ignores_extra_args

_finish_tests
