#!/bin/sh
# Tests for the 'assert-output-contains' imp

. "${0%/*}/../test_common.sh"

test_assert_output_contains_exists() {
  [ -x "$ROOT_DIR/spells/.imps/assert-output-contains" ]
}

run_test_case "assert-output-contains is executable" test_assert_output_contains_exists

finish_tests
