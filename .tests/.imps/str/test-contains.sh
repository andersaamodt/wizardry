#!/bin/sh
# Tests for the 'contains' imp

. "${0%/*}/../../test-common.sh"

test_contains_finds_substring() {
  run_spell spells/.imps/str/contains "hello world" "wor"
  assert_success
}

test_contains_rejects_missing() {
  run_spell spells/.imps/str/contains "hello world" "xyz"
  assert_failure
}

run_test_case "contains finds substring" test_contains_finds_substring
run_test_case "contains rejects missing substring" test_contains_rejects_missing

finish_tests
