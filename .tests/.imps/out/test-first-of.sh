#!/bin/sh
# Tests for the 'or' imp

. "${0%/*}/../../test-common.sh"

test_or_first() {
  run_spell spells/.imps/out/first-of "first" "second"
  assert_success
  assert_output_contains "first"
}

test_or_second() {
  run_spell spells/.imps/out/first-of "" "second"
  assert_success
  assert_output_contains "second"
}

test_or_fails_both_empty() {
  run_spell spells/.imps/out/first-of "" ""
  assert_failure
}

run_test_case "first-of returns first non-empty" test_or_first
run_test_case "first-of returns second if first empty" test_or_second
run_test_case "first-of fails if both empty" test_or_fails_both_empty

finish_tests
