#!/bin/sh
# Tests for the 'test-assert-failure' imp

. "${0%/*}/../test-common.sh"

test_test_assert_failure_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test-assert-failure" ]
}

run_test_case "test-assert-failure is executable" test_test_assert_failure_exists

finish_tests
