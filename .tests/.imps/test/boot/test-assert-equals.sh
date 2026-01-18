#!/bin/sh
# Test assert-equals imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_equal_strings() {
  assert_equals "hello" "hello"
}

test_equal_numbers() {
  assert_equals "42" "42"
}

test_equal_empty_strings() {
  assert_equals "" ""
}

test_unequal_strings_fails() {
  if assert_equals "hello" "world"; then
    return 1
  fi
  return 0
}

test_unequal_numbers_fails() {
  if assert_equals "42" "24"; then
    return 1
  fi
  return 0
}

run_test_case "assert-equals succeeds on equal strings" test_equal_strings
run_test_case "assert-equals succeeds on equal numbers" test_equal_numbers
run_test_case "assert-equals succeeds on empty strings" test_equal_empty_strings
run_test_case "assert-equals fails on unequal strings" test_unequal_strings_fails
run_test_case "assert-equals fails on unequal numbers" test_unequal_numbers_fails

finish_tests
