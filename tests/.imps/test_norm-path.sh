#!/bin/sh
# Tests for the 'norm-path' imp

. "${0%/*}/../test_common.sh"

test_norm_path_normalizes() {
  run_spell spells/.imps/norm-path "/tmp//test"
  assert_success
  # Should normalize double slashes
  case "$OUTPUT" in
    *//*) TEST_FAILURE_REASON="should normalize double slashes"; return 1 ;;
  esac
}

run_test_case "norm-path normalizes path" test_norm_path_normalizes

finish_tests
