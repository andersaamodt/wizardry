#!/bin/sh
# Tests for the 'assert-error-contains' imp

. "${0%/*}/../test_common.sh"

test_assert_error_contains_exists() {
  [ -x "$ROOT_DIR/spells/.imps/assert-error-contains" ]
}

run_test_case "assert-error-contains is executable" test_assert_error_contains_exists

finish_tests
