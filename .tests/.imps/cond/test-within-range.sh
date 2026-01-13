#!/bin/sh
# Tests for the 'within-range' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_within_range_middle() {
  run_spell spells/.imps/cond/within-range 5 1 10
  assert_success
}

test_within_range_at_min() {
  skip-if-compiled || return $?
  run_spell spells/.imps/cond/within-range 1 1 10
  assert_success
}

test_within_range_at_max() {
  skip-if-compiled || return $?
  run_spell spells/.imps/cond/within-range 10 1 10
  assert_success
}

test_within_range_below_min() {
  skip-if-compiled || return $?
  run_spell spells/.imps/cond/within-range 0 1 10
  assert_failure
}

test_within_range_above_max() {
  skip-if-compiled || return $?
  run_spell spells/.imps/cond/within-range 11 1 10
  assert_failure
}

run_test_case "within-range accepts middle" test_within_range_middle
run_test_case "within-range accepts at min" test_within_range_at_min
run_test_case "within-range accepts at max" test_within_range_at_max
run_test_case "within-range rejects below min" test_within_range_below_min
run_test_case "within-range rejects above max" test_within_range_above_max

finish_tests
