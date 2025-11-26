#!/bin/sh
# Tests for the 'where' imp

. "${0%/*}/../test-common.sh"

test_where_finds_command() {
  run_spell spells/.imps/where sh
  assert_success
  [ -x "$OUTPUT" ] || { TEST_FAILURE_REASON="should output executable path"; return 1; }
}

test_where_fails_for_missing() {
  run_spell spells/.imps/where nonexistent_command_xyz123
  assert_failure
}

run_test_case "where finds command" test_where_finds_command
run_test_case "where fails for missing command" test_where_fails_for_missing

finish_tests
