#!/bin/sh
# Tests for the 'test-assert-success' imp

. "${0%/*}/../test-common.sh"

test_test_assert_success_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test-assert-success" ]
}

run_test_case "test-assert-success is executable" test_test_assert_success_exists

finish_tests
