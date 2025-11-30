#!/bin/sh
# Tests for the 'die' imp

. "${0%/*}/../../test-common.sh"

test_die_exits_with_message() {
  run_spell spells/.imps/out/die "fatal error"
  assert_failure
  assert_error_contains "fatal error"
}

test_die_accepts_custom_exit_code() {
  run_spell spells/.imps/out/die 42 "custom code"
  [ "$STATUS" -eq 42 ] || { TEST_FAILURE_REASON="expected status 42, got $STATUS"; return 1; }
}

run_test_case "die exits with message" test_die_exits_with_message
run_test_case "die accepts custom exit code" test_die_accepts_custom_exit_code

finish_tests
