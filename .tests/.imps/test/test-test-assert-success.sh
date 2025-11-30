#!/bin/sh
# Tests for the 'test-assert-success' imp

. "${0%/*}/../../test-common.sh"

test_test_assert_success_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/test-assert-success" ]
}

test_test_assert_success_succeeds_on_zero() {
  STATUS=0
  export STATUS
  run_spell spells/.imps/test/test-assert-success
  assert_success
}

run_test_case "test-assert-success is executable" test_test_assert_success_exists
run_test_case "test-assert-success succeeds on zero" test_test_assert_success_succeeds_on_zero

finish_tests
