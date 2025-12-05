#!/bin/sh
# Tests for the 'tty-raw' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

# Note: tty-raw requires an actual terminal for full functionality
# In CI, we test basic invocation behavior

test_tty_raw_runs() {
  # Running without a terminal may succeed or fail depending on environment
  run_spell spells/.imps/input/tty-raw
  # We just ensure it doesn't crash unexpectedly
}

test_tty_raw_ignores_extra_args() {
  # Extra arguments should be ignored (POSIX-compliant imps are simpler)
  run_spell spells/.imps/input/tty-raw ignored_arg
  # We just ensure it doesn't crash unexpectedly
}

run_test_case "tty-raw runs" test_tty_raw_runs
run_test_case "tty-raw ignores extra args" test_tty_raw_ignores_extra_args

finish_tests
