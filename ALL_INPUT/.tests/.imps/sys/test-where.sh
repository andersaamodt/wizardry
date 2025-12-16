#!/bin/sh
# Tests for the 'where' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_where_finds_command() {
  _run_spell spells/.imps/sys/where sh
  _assert_success
  [ -x "$OUTPUT" ] || { TEST_FAILURE_REASON="should output executable path"; return 1; }
}

test_where_fails_for_missing() {
  _run_spell spells/.imps/sys/where nonexistent_command_xyz123
  _assert_failure
}

_run_test_case "where finds command" test_where_finds_command
_run_test_case "where fails for missing command" test_where_fails_for_missing

_finish_tests
