#!/bin/sh
# Tests for the 'in-range' imp

. "${0%/*}/../test-common.sh"

test_in_range_middle() {
  run_spell spells/.imps/in-range 5 1 10
  assert_success
}

test_in_range_at_min() {
  run_spell spells/.imps/in-range 1 1 10
  assert_success
}

test_in_range_at_max() {
  run_spell spells/.imps/in-range 10 1 10
  assert_success
}

test_in_range_below_min() {
  run_spell spells/.imps/in-range 0 1 10
  assert_failure
}

test_in_range_above_max() {
  run_spell spells/.imps/in-range 11 1 10
  assert_failure
}

run_test_case "in-range accepts middle" test_in_range_middle
run_test_case "in-range accepts at min" test_in_range_at_min
run_test_case "in-range accepts at max" test_in_range_at_max
run_test_case "in-range rejects below min" test_in_range_below_min
run_test_case "in-range rejects above max" test_in_range_above_max

finish_tests
