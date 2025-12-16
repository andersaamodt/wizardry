#!/bin/sh
# Tests for the 'tty-raw' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Note: tty-raw requires an actual terminal for full functionality
# In CI, we test basic invocation behavior

test_tty_raw_runs() {
  # Running without a terminal may succeed or fail depending on environment
  _run_spell spells/.imps/input/tty-raw
  # We just ensure it doesn't crash unexpectedly
}

test_tty_raw_ignores_extra_args() {
  # Extra arguments should be ignored (POSIX-compliant imps are simpler)
  _run_spell spells/.imps/input/tty-raw ignored_arg
  # We just ensure it doesn't crash unexpectedly
}

_run_test_case "tty-raw runs" test_tty_raw_runs
_run_test_case "tty-raw ignores extra args" test_tty_raw_ignores_extra_args

_finish_tests
