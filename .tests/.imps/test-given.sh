#!/bin/sh
# Tests for the 'given' imp

. "${0%/*}/../test-common.sh"

test_given_succeeds_for_nonempty() {
  run_spell spells/.imps/given "something"
  assert_success
}

test_given_fails_for_empty() {
  run_spell spells/.imps/given ""
  assert_failure
}

run_test_case "given succeeds for non-empty string" test_given_succeeds_for_nonempty
run_test_case "given fails for empty string" test_given_fails_for_empty

finish_tests
