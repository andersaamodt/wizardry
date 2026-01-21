#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_runs_simple_command() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  PTY_INPUT='test
' run_spell "spells/.imps/test/run-with-pty" cat
  assert_success || return 1
  assert_output_contains "test" || return 1
}

run_test_case "run-with-pty runs simple command" test_runs_simple_command
finish_tests
