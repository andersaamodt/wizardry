#!/bin/sh
# Tests for the 'need' imp

. "${0%/*}/../../test-common.sh"

test_need_existing_command() {
  run_spell spells/.imps/sys/need sh
  assert_success
}

test_need_missing_command() {
  run_spell spells/.imps/sys/need nonexistent_command_xyz123
  assert_failure
  assert_error_contains "nonexistent_command_xyz123"
}

test_need_custom_message() {
  run_spell spells/.imps/sys/need nonexistent_command_xyz123 "custom error message"
  assert_failure
  assert_error_contains "custom error message"
}

run_test_case "need succeeds for existing command" test_need_existing_command
run_test_case "need fails for missing command" test_need_missing_command
run_test_case "need shows custom message" test_need_custom_message

finish_tests
