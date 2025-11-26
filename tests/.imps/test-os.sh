#!/bin/sh
# Tests for the 'os' imp

. "${0%/*}/../test-common.sh"

test_os_outputs_name() {
  run_spell spells/.imps/os
  assert_success
  # Should output a non-empty OS name
  [ -n "$OUTPUT" ] || { TEST_FAILURE_REASON="should output OS name"; return 1; }
}

test_os_outputs_lowercase() {
  run_spell spells/.imps/os
  assert_success
  # Output should be lowercase
  case "$OUTPUT" in
    *[A-Z]*) TEST_FAILURE_REASON="output should be lowercase"; return 1 ;;
    *) return 0 ;;
  esac
}

run_test_case "os outputs name" test_os_outputs_name
run_test_case "os outputs lowercase" test_os_outputs_lowercase

finish_tests
