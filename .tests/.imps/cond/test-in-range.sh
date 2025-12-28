#!/bin/sh
# Tests for the 'in-range' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_in_range_middle() {
  run_spell spells/.imps/cond/in-range 5 1 10
  assert_success
}

test_in_range_at_min() {
  skip-if-compiled || return $?
  run_spell spells/.imps/cond/in-range 1 1 10
  assert_success
}

test_in_range_at_max() {
  skip-if-compiled || return $?
  run_spell spells/.imps/cond/in-range 10 1 10
  assert_success
}

test_in_range_below_min() {
  skip-if-compiled || return $?
  run_spell spells/.imps/cond/in-range 0 1 10
  assert_failure
}

test_in_range_above_max() {
  skip-if-compiled || return $?
  run_spell spells/.imps/cond/in-range 11 1 10
  assert_failure
}

run_test_case "in-range accepts middle" test_in_range_middle
run_test_case "in-range accepts at min" test_in_range_at_min
run_test_case "in-range accepts at max" test_in_range_at_max
run_test_case "in-range rejects below min" test_in_range_below_min
run_test_case "in-range rejects above max" test_in_range_above_max

finish_tests
