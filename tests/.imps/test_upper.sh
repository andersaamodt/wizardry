#!/bin/sh
# Tests for the 'upper' imp

. "${0%/*}/../test_common.sh"

test_upper_converts() {
  run_cmd sh -c "printf 'hello' | '$ROOT_DIR/spells/.imps/upper'"
  assert_success
  assert_output_contains "HELLO"
}

run_test_case "upper converts to uppercase" test_upper_converts

finish_tests
