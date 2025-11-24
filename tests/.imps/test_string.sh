#!/bin/sh
# Tests for string imps: holds, starts, ends, say, warn

. "${0%/*}/../test_common.sh"

test_holds_contains() {
  run_spell spells/.imps/holds "hello world" "wor"
  assert_success
}

test_holds_not_contains() {
  run_spell spells/.imps/holds "hello world" "xyz"
  assert_failure
}

test_starts_with() {
  run_spell spells/.imps/starts "hello world" "hello"
  assert_success
}

test_starts_not() {
  run_spell spells/.imps/starts "hello world" "world"
  assert_failure
}

test_ends_with() {
  run_spell spells/.imps/ends "hello world" "world"
  assert_success
}

test_ends_not() {
  run_spell spells/.imps/ends "hello world" "hello"
  assert_failure
}

test_say_outputs() {
  run_spell spells/.imps/say "test message"
  assert_success
  assert_output_contains "test message"
}

test_warn_to_stderr() {
  run_spell spells/.imps/warn "warning message"
  assert_success
  assert_error_contains "warning message"
}

test_yes_affirms() {
  run_spell spells/.imps/yes "y"
  assert_success
}

test_yes_affirms_yes() {
  run_spell spells/.imps/yes "yes"
  assert_success
}

test_yes_affirms_true() {
  run_spell spells/.imps/yes "true"
  assert_success
}

test_yes_rejects_no() {
  run_spell spells/.imps/yes "no"
  assert_failure
}

test_yes_rejects_empty() {
  run_spell spells/.imps/yes ""
  assert_failure
}

run_test_case "holds finds substring" test_holds_contains
run_test_case "holds rejects missing substring" test_holds_not_contains
run_test_case "starts matches prefix" test_starts_with
run_test_case "starts rejects non-prefix" test_starts_not
run_test_case "ends matches suffix" test_ends_with
run_test_case "ends rejects non-suffix" test_ends_not
run_test_case "say outputs to stdout" test_say_outputs
run_test_case "warn outputs to stderr" test_warn_to_stderr
run_test_case "yes affirms y" test_yes_affirms
run_test_case "yes affirms yes" test_yes_affirms_yes
run_test_case "yes affirms true" test_yes_affirms_true
run_test_case "yes rejects no" test_yes_rejects_no
run_test_case "yes rejects empty" test_yes_rejects_empty

finish_tests
