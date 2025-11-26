#!/bin/sh
# Tests for the 'has' imp

. "${0%/*}/../test_common.sh"

test_has_existing_command() {
  run_spell spells/.imps/has sh
  assert_success
}

test_has_missing_command() {
  run_spell spells/.imps/has nonexistent_command_xyz123
  assert_failure
}

run_test_case "has succeeds for existing command" test_has_existing_command
run_test_case "has fails for missing command" test_has_missing_command

finish_tests
