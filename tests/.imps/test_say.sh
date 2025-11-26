#!/bin/sh
# Tests for the 'say' imp

. "${0%/*}/../test_common.sh"

test_say_outputs() {
  run_spell spells/.imps/say "test message"
  assert_success
  assert_output_contains "test message"
}

run_test_case "say outputs to stdout" test_say_outputs

finish_tests
