#!/bin/sh
# Tests for the 'path' imp

. "${0%/*}/../../test-common.sh"

test_path_normalizes() {
  run_spell spells/.imps/paths/path "./test"
  assert_success
  # Should output an absolute path
  case "$OUTPUT" in
    /*) return 0 ;;
    *) TEST_FAILURE_REASON="should output absolute path"; return 1 ;;
  esac
}

test_path_handles_absolute_input() {
  run_spell spells/.imps/paths/path "/tmp/test"
  assert_success
  assert_output_contains "/tmp/test"
}

run_test_case "path normalizes relative path" test_path_normalizes
run_test_case "path handles absolute input" test_path_handles_absolute_input

finish_tests
