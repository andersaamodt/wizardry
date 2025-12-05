#!/bin/sh
# Tests for the 'lacks' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_lacks_missing_command() {
  run_spell spells/.imps/cond/lacks nonexistent_command_xyz123
  assert_success
}

test_lacks_existing_command() {
  run_spell spells/.imps/cond/lacks sh
  assert_failure
}

run_test_case "lacks succeeds for missing command" test_lacks_missing_command
run_test_case "lacks fails for existing command" test_lacks_existing_command

finish_tests
