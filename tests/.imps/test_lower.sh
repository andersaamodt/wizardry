#!/bin/sh
# Tests for the 'lower' imp

. "${0%/*}/../test_common.sh"

test_lower_converts() {
  run_cmd sh -c "printf 'HELLO' | '$ROOT_DIR/spells/.imps/lower'"
  assert_success
  assert_output_contains "hello"
}

run_test_case "lower converts to lowercase" test_lower_converts

finish_tests
