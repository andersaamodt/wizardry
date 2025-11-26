#!/bin/sh
# Tests for the 'path' imp

. "${0%/*}/../test-common.sh"

test_path_normalizes() {
  run_spell spells/.imps/path "./test"
  assert_success
  # Should output an absolute path
  case "$OUTPUT" in
    /*) return 0 ;;
    *) TEST_FAILURE_REASON="should output absolute path"; return 1 ;;
  esac
}

run_test_case "path normalizes relative path" test_path_normalizes

finish_tests
