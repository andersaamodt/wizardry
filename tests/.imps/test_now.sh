#!/bin/sh
# Tests for the 'now' imp

. "${0%/*}/../test_common.sh"

test_now_outputs_timestamp() {
  run_spell spells/.imps/now
  assert_success
  # Should output a number (Unix timestamp)
  case "$OUTPUT" in
    *[!0-9]*) TEST_FAILURE_REASON="should output number"; return 1 ;;
  esac
}

run_test_case "now outputs timestamp" test_now_outputs_timestamp

finish_tests
