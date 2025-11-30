#!/bin/sh
# Tests for the 'count-chars' imp

. "${0%/*}/../../test-common.sh"

test_count_chars_simple() {
  run_spell spells/.imps/text/count-chars "hello"
  assert_success
  assert_output_contains "5"
}

test_count_chars_empty() {
  run_spell spells/.imps/text/count-chars ""
  assert_success
  assert_output_contains "0"
}

run_test_case "count-chars counts simple string" test_count_chars_simple
run_test_case "count-chars handles empty" test_count_chars_empty

finish_tests
