#!/bin/sh
# Tests for the 'has' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_has_existing_command() {
  _run_spell spells/.imps/cond/has sh
  _assert_success
}

test_has_missing_command() {
  _run_spell spells/.imps/cond/has nonexistent_command_xyz123
  _assert_failure
}

_run_test_case "has succeeds for existing command" test_has_existing_command
_run_test_case "has fails for missing command" test_has_missing_command

_finish_tests
