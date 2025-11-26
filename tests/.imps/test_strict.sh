#!/bin/sh
# Tests for the 'strict' imp

. "${0%/*}/../test_common.sh"

test_strict_exists() {
  [ -x "$ROOT_DIR/spells/.imps/strict" ]
}

run_test_case "strict is executable" test_strict_exists

finish_tests
