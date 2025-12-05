#!/bin/sh
# Tests for the 'fail' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_fail_exits_with_message() {
  _run_spell spells/.imps/out/fail "error message"
  _assert_failure
  _assert_error_contains "error message"
}

test_fail_exits_with_status_1() {
  _run_spell spells/.imps/out/fail "test"
  [ "$STATUS" -eq 1 ] || { TEST_FAILURE_REASON="expected status 1, got $STATUS"; return 1; }
}

_run_test_case "fail exits with message" test_fail_exits_with_message
_run_test_case "fail exits with status 1" test_fail_exits_with_status_1

_finish_tests
