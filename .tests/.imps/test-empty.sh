#!/bin/sh
# Tests for the 'empty' imp

. "${0%/*}/../test-common.sh"

test_empty_succeeds_for_empty() {
  run_spell spells/.imps/empty ""
  assert_success
}

test_empty_fails_for_nonempty() {
  run_spell spells/.imps/empty "something"
  assert_failure
}

run_test_case "empty succeeds for empty string" test_empty_succeeds_for_empty
run_test_case "empty fails for non-empty string" test_empty_fails_for_nonempty

finish_tests
