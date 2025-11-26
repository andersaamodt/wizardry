#!/bin/sh
# Tests for the 'warn' imp

. "${0%/*}/../test_common.sh"

test_warn_to_stderr() {
  run_spell spells/.imps/warn "warning message"
  assert_success
  assert_error_contains "warning message"
}

run_test_case "warn outputs to stderr" test_warn_to_stderr

finish_tests
