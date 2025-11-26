#!/bin/sh
# Tests for the 'die' imp

. "${0%/*}/../test-common.sh"

test_die_exits_with_message() {
  run_spell spells/.imps/die "fatal error"
  assert_failure
  assert_error_contains "fatal error"
}

run_test_case "die exits with message" test_die_exits_with_message

finish_tests
