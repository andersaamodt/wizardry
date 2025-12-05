#!/bin/sh
# Tests for the 'say' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_say_outputs() {
  run_spell spells/.imps/out/say "test message"
  assert_success
  assert_output_contains "test message"
}

test_say_handles_empty_message() {
  run_spell spells/.imps/out/say ""
  assert_success
}

run_test_case "say outputs to stdout" test_say_outputs
run_test_case "say handles empty message" test_say_handles_empty_message

finish_tests
