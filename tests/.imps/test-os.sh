#!/bin/sh
# Tests for the 'os' imp

. "${0%/*}/../test-common.sh"

test_os_outputs_name() {
  run_spell spells/.imps/os
  assert_success
  # Should output a non-empty OS name
  [ -n "$OUTPUT" ] || { TEST_FAILURE_REASON="should output OS name"; return 1; }
}

run_test_case "os outputs name" test_os_outputs_name

finish_tests
