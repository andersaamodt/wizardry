#!/bin/sh
# Tests for the 'has', 'lacks', 'need', and 'any' imps

. "${0%/*}/../test_common.sh"

test_has_existing_command() {
  run_spell spells/.imps/has sh
  assert_success
}

test_has_missing_command() {
  run_spell spells/.imps/has nonexistent_command_xyz123
  assert_failure
}

test_lacks_missing_command() {
  run_spell spells/.imps/lacks nonexistent_command_xyz123
  assert_success
}

test_lacks_existing_command() {
  run_spell spells/.imps/lacks sh
  assert_failure
}

test_need_existing_command() {
  run_spell spells/.imps/need sh
  assert_success
}

test_need_missing_command() {
  run_spell spells/.imps/need nonexistent_command_xyz123
  assert_failure
  assert_error_contains "nonexistent_command_xyz123"
}

test_need_custom_message() {
  run_spell spells/.imps/need nonexistent_command_xyz123 "custom error message"
  assert_failure
  assert_error_contains "custom error message"
}

test_any_finds_first() {
  run_spell spells/.imps/any sh nonexistent_xyz
  assert_success
  assert_output_contains "sh"
}

test_any_finds_second() {
  run_spell spells/.imps/any nonexistent_xyz sh
  assert_success
  assert_output_contains "sh"
}

test_any_fails_when_none_exist() {
  run_spell spells/.imps/any nonexistent_xyz1 nonexistent_xyz2
  assert_failure
}

run_test_case "has succeeds for existing command" test_has_existing_command
run_test_case "has fails for missing command" test_has_missing_command
run_test_case "lacks succeeds for missing command" test_lacks_missing_command
run_test_case "lacks fails for existing command" test_lacks_existing_command
run_test_case "need succeeds for existing command" test_need_existing_command
run_test_case "need fails for missing command" test_need_missing_command
run_test_case "need shows custom message" test_need_custom_message
run_test_case "any finds first available" test_any_finds_first
run_test_case "any finds second if first missing" test_any_finds_second
run_test_case "any fails when none exist" test_any_fails_when_none_exist

finish_tests
