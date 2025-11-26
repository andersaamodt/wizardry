#!/bin/sh
# Tests for the 'fail' imp

. "${0%/*}/../test-common.sh"

test_fail_exits_with_message() {
  run_spell spells/.imps/fail "error message"
  assert_failure
  assert_error_contains "error message"
}

run_test_case "fail exits with message" test_fail_exits_with_message

finish_tests
