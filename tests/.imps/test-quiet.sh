#!/bin/sh
# Tests for the 'quiet' imp

. "${0%/*}/../test-common.sh"

test_quiet_suppresses_output() {
  run_spell spells/.imps/quiet echo "should be silent"
  assert_success
  # Output should be empty
  if [ -n "$OUTPUT" ]; then
    TEST_FAILURE_REASON="output should be empty"
    return 1
  fi
}

test_quiet_preserves_exit_status() {
  run_spell spells/.imps/quiet false
  assert_failure
}

run_test_case "quiet suppresses output" test_quiet_suppresses_output
run_test_case "quiet preserves exit status" test_quiet_preserves_exit_status

finish_tests
