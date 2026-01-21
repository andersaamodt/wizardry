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

test_sends_symbolic_keys() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  # PTY_KEYS should convert symbolic keys to escape sequences
  # We can't easily test arrow keys, but we can test that enter becomes \r
  PTY_KEYS="enter" run_spell "spells/.imps/test/run-with-pty" cat
  assert_success || return 1
}

run_test_case "run-with-pty runs simple command" test_runs_simple_command
run_test_case "run-with-pty sends symbolic keys" test_sends_symbolic_keys
finish_tests
