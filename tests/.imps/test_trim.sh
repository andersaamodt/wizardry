#!/bin/sh
# Tests for the 'trim' imp

. "${0%/*}/../test_common.sh"

test_trim_removes_whitespace() {
  run_cmd sh -c "printf '  hello  ' | '$ROOT_DIR/spells/.imps/trim'"
  assert_success
  assert_output_contains "hello"
}

run_test_case "trim removes whitespace" test_trim_removes_whitespace

finish_tests
