#!/bin/sh
# Tests for the 'here' imp

. "${0%/*}/../test-common.sh"

test_here_outputs_directory() {
  run_spell spells/.imps/here
  assert_success
  # Should output a path
  [ -d "$OUTPUT" ] || { TEST_FAILURE_REASON="should output directory"; return 1; }
}

run_test_case "here outputs current directory" test_here_outputs_directory

finish_tests
