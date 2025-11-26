#!/bin/sh
# Tests for the 'equals' imp

. "${0%/*}/../test_common.sh"

test_equals_same_string() {
  run_spell spells/.imps/equals "hello" "hello"
  assert_success
}

test_equals_different_strings() {
  run_spell spells/.imps/equals "hello" "world"
  assert_failure
}

run_test_case "equals accepts same string" test_equals_same_string
run_test_case "equals rejects different strings" test_equals_different_strings

finish_tests
