#!/bin/sh
# Tests for the 'ok' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_ok_succeeds_when_command_succeeds() {
  run_spell spells/.imps/out/ok true
  assert_success
}

test_ok_fails_when_command_fails() {
  run_spell spells/.imps/out/ok false
  assert_failure
}

run_test_case "ok succeeds when command succeeds" test_ok_succeeds_when_command_succeeds
run_test_case "ok fails when command fails" test_ok_fails_when_command_fails

finish_tests
