#!/bin/sh
# Tests for the 'lacks' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_lacks_missing_command() {
  run_spell spells/.imps/cond/lacks nonexistent_command_xyz123
  assert_success
}

test_lacks_existing_command() {
  run_spell spells/.imps/cond/lacks sh
  assert_failure
}

run_test_case "lacks succeeds for missing command" test_lacks_missing_command
run_test_case "lacks fails for existing command" test_lacks_existing_command

finish_tests
