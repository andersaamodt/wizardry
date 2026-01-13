#!/bin/sh
# Tests for the 'on-exit' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_on_exit_succeeds() {
  run_spell spells/.imps/sys/on-exit "echo cleanup"
  assert_success
}

test_on_exit_accepts_complex_command() {
  run_spell spells/.imps/sys/on-exit "rm -f /tmp/test && echo done"
  assert_success
}

run_test_case "on-exit sets trap successfully" test_on_exit_succeeds
run_test_case "on-exit accepts complex command" test_on_exit_accepts_complex_command

finish_tests
