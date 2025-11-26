#!/bin/sh
# Tests for the 'test-assert-output-contains' imp

. "${0%/*}/../test-common.sh"

test_test_assert_output_contains_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test-assert-output-contains" ]
}

run_test_case "test-assert-output-contains is executable" test_test_assert_output_contains_exists

finish_tests
