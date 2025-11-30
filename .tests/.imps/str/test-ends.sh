#!/bin/sh
# Tests for the 'ends' imp

. "${0%/*}/../../test-common.sh"

test_ends_with() {
  run_spell spells/.imps/str/ends "hello world" "world"
  assert_success
}

test_ends_not() {
  run_spell spells/.imps/str/ends "hello world" "hello"
  assert_failure
}

run_test_case "ends matches suffix" test_ends_with
run_test_case "ends rejects non-suffix" test_ends_not

finish_tests
