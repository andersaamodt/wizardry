#!/bin/sh
# Tests for the 'assert-failure' imp

. "${0%/*}/../test_common.sh"

test_assert_failure_exists() {
  [ -x "$ROOT_DIR/spells/.imps/assert-failure" ]
}

run_test_case "assert-failure is executable" test_assert_failure_exists

finish_tests
