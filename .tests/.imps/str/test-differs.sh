#!/bin/sh
# Tests for the 'differs' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_differs_different_strings() {
  run_spell spells/.imps/str/differs "hello" "world"
  assert_success
}

test_differs_same_string() {
  run_spell spells/.imps/str/differs "hello" "hello"
  assert_failure
}

run_test_case "differs accepts different strings" test_differs_different_strings
run_test_case "differs rejects same string" test_differs_same_string

finish_tests
