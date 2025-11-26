#!/bin/sh
# Tests for the 'or' imp

. "${0%/*}/../test_common.sh"

test_or_first() {
  run_spell spells/.imps/or "first" "second"
  assert_success
  assert_output_contains "first"
}

test_or_second() {
  run_spell spells/.imps/or "" "second"
  assert_success
  assert_output_contains "second"
}

test_or_fails_both_empty() {
  run_spell spells/.imps/or "" ""
  assert_failure
}

run_test_case "or returns first non-empty" test_or_first
run_test_case "or returns second if first empty" test_or_second
run_test_case "or fails if both empty" test_or_fails_both_empty

finish_tests
