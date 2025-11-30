#!/bin/sh
# Tests for the 'test-assert-error-contains' imp

. "${0%/*}/../../test-common.sh"

test_test_assert_error_contains_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/test-assert-error-contains" ]
}

test_test_assert_error_contains_finds_substring() {
  ERROR="this is an error message"
  export ERROR
  run_spell spells/.imps/test/test-assert-error-contains "error"
  assert_success
}

run_test_case "test-assert-error-contains is executable" test_test_assert_error_contains_exists
run_test_case "test-assert-error-contains finds substring" test_test_assert_error_contains_finds_substring

finish_tests
