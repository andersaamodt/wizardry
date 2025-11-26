#!/bin/sh
# Tests for the 'starts' imp

. "${0%/*}/../test_common.sh"

test_starts_with() {
  run_spell spells/.imps/starts "hello world" "hello"
  assert_success
}

test_starts_not() {
  run_spell spells/.imps/starts "hello world" "world"
  assert_failure
}

run_test_case "starts matches prefix" test_starts_with
run_test_case "starts rejects non-prefix" test_starts_not

finish_tests
