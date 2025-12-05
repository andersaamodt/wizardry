#!/bin/sh
# Tests for the 'quiet' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_quiet_suppresses_output() {
  run_spell spells/.imps/out/quiet echo "should be silent"
  assert_success
  # Output should be empty
  if [ -n "$OUTPUT" ]; then
    TEST_FAILURE_REASON="output should be empty"
    return 1
  fi
}

test_quiet_preserves_exit_status() {
  run_spell spells/.imps/out/quiet false
  assert_failure
}

run_test_case "quiet suppresses output" test_quiet_suppresses_output
run_test_case "quiet preserves exit status" test_quiet_preserves_exit_status

finish_tests
