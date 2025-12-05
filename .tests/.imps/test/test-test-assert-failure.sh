#!/bin/sh
# Tests for the 'test-assert-failure' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_test_assert_failure_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/test-assert-failure" ]
}

test_test_assert_failure_succeeds_on_nonzero() {
  STATUS=1
  export STATUS
  run_spell spells/.imps/test/test-assert-failure
  assert_success
}

run_test_case "test-assert-failure is executable" test_test_assert_failure_exists
run_test_case "test-assert-failure succeeds on nonzero" test_test_assert_failure_succeeds_on_nonzero

finish_tests
