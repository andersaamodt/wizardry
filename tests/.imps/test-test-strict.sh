#!/bin/sh
# Tests for the 'test-strict' imp

. "${0%/*}/../test-common.sh"

test_test_strict_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test-strict" ]
}

run_test_case "test-strict is executable" test_test_strict_exists

finish_tests
