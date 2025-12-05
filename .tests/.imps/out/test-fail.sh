#!/bin/sh
# Tests for the 'fail' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_fail_exits_with_message() {
  run_spell spells/.imps/out/fail "error message"
  assert_failure
  assert_error_contains "error message"
}

test_fail_exits_with_status_1() {
  run_spell spells/.imps/out/fail "test"
  [ "$STATUS" -eq 1 ] || { TEST_FAILURE_REASON="expected status 1, got $STATUS"; return 1; }
}

run_test_case "fail exits with message" test_fail_exits_with_message
run_test_case "fail exits with status 1" test_fail_exits_with_status_1

finish_tests
