#!/bin/sh
# Tests for the 'assert-success' imp

. "${0%/*}/../test-common.sh"

test_assert_success_exists() {
  [ -x "$ROOT_DIR/spells/.imps/assert-success" ]
}

run_test_case "assert-success is executable" test_assert_success_exists

finish_tests
