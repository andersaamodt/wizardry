#!/bin/sh
# Tests for the 'starts' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_starts_with() {
  run_spell spells/.imps/str/starts "hello world" "hello"
  assert_success
}

test_starts_not() {
  run_spell spells/.imps/str/starts "hello world" "world"
  assert_failure
}

run_test_case "starts matches prefix" test_starts_with
run_test_case "starts rejects non-prefix" test_starts_not

finish_tests
