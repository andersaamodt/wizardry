#!/bin/sh
# Tests for the 'field' imp

. "${0%/*}/../../test-common.sh"

test_field_with_delimiter() {
  run_cmd sh -c "printf 'a:b:c' | '$ROOT_DIR/spells/.imps/text/field' 2 ':'"
  assert_success
  assert_output_contains "b"
}

test_field_whitespace_default() {
  run_cmd sh -c "printf 'one two three' | '$ROOT_DIR/spells/.imps/text/field' 2"
  assert_success
  assert_output_contains "two"
}

run_test_case "field extracts with delimiter" test_field_with_delimiter
run_test_case "field uses whitespace default" test_field_whitespace_default

finish_tests
