#!/bin/sh
# Tests for the 'test-strict' imp

. "${0%/*}/../test-common.sh"

test_test_strict_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test-strict" ]
}

test_test_strict_is_sourceable() {
  [ -f "$ROOT_DIR/spells/.imps/test-strict" ] || { TEST_FAILURE_REASON="file should exist"; return 1; }
}

run_test_case "test-strict is executable" test_test_strict_exists
run_test_case "test-strict is sourceable" test_test_strict_is_sourceable

finish_tests
