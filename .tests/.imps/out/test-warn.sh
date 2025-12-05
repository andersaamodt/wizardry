#!/bin/sh
# Tests for the 'warn' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_warn_to_stderr() {
  run_spell spells/.imps/out/warn "warning message"
  assert_success
  assert_error_contains "warning message"
}

test_warn_succeeds_with_empty_message() {
  run_spell spells/.imps/out/warn ""
  assert_success
}

run_test_case "warn outputs to stderr" test_warn_to_stderr
run_test_case "warn succeeds with empty message" test_warn_succeeds_with_empty_message

finish_tests
