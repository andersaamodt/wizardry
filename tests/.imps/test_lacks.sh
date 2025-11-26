#!/bin/sh
# Tests for the 'lacks' imp

. "${0%/*}/../test_common.sh"

test_lacks_missing_command() {
  run_spell spells/.imps/lacks nonexistent_command_xyz123
  assert_success
}

test_lacks_existing_command() {
  run_spell spells/.imps/lacks sh
  assert_failure
}

run_test_case "lacks succeeds for missing command" test_lacks_missing_command
run_test_case "lacks fails for existing command" test_lacks_existing_command

finish_tests
