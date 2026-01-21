#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_runs_with_input() {
  # Skip if socat not available
  if ! command -v socat >/dev/null 2>&1; then
    test_skip "requires socat"
    return 0
  fi
  
  run_spell "spells/.imps/test/socat-test" "hello\n" cat
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

run_test_case "socat-test runs with input" test_runs_with_input
finish_tests
