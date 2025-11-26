#!/bin/sh
# Tests for the 'test-assert-error-contains' imp

. "${0%/*}/../test-common.sh"

test_test_assert_error_contains_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test-assert-error-contains" ]
}

run_test_case "test-assert-error-contains is executable" test_test_assert_error_contains_exists

finish_tests
