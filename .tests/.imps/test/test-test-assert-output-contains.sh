#!/bin/sh
# Tests for the 'test-assert-output-contains' imp

. "${0%/*}/../../test-common.sh"

test_test_assert_output_contains_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/test-assert-output-contains" ]
}

test_test_assert_output_contains_finds_substring() {
  OUTPUT="this is the output"
  export OUTPUT
  run_spell spells/.imps/test/test-assert-output-contains "output"
  assert_success
}

run_test_case "test-assert-output-contains is executable" test_test_assert_output_contains_exists
run_test_case "test-assert-output-contains finds substring" test_test_assert_output_contains_finds_substring

finish_tests
