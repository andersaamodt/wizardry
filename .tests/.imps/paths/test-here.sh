#!/bin/sh
# Tests for the 'here' imp

. "${0%/*}/../../test-common.sh"

test_here_outputs_directory() {
  run_spell spells/.imps/paths/here
  assert_success
  # Should output a path
  [ -d "$OUTPUT" ] || { TEST_FAILURE_REASON="should output directory"; return 1; }
}

test_here_outputs_normalized_path() {
  run_spell spells/.imps/paths/here
  assert_success
  case "$OUTPUT" in
    *///*) TEST_FAILURE_REASON="path should be normalized"; return 1 ;;
    *) return 0 ;;
  esac
}

run_test_case "here outputs current directory" test_here_outputs_directory
run_test_case "here outputs normalized path" test_here_outputs_normalized_path

finish_tests
