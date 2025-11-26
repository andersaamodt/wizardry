#!/bin/sh
# Tests for string imps: contains, starts, ends, say, warn

. "${0%/*}/../test_common.sh"

test_contains_finds_substring() {
  run_spell spells/.imps/contains "hello world" "wor"
  assert_success
}

test_contains_rejects_missing() {
  run_spell spells/.imps/contains "hello world" "xyz"
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

# Additional yes tests
test_yes_affirms_Y() {
  run_spell spells/.imps/yes "Y"
  assert_success
}

test_yes_affirms_YES() {
  run_spell spells/.imps/yes "YES"
  assert_success
}

test_yes_affirms_TRUE() {
  run_spell spells/.imps/yes "TRUE"
  assert_success
}

test_yes_affirms_1() {
  run_spell spells/.imps/yes "1"
  assert_success
}

test_yes_rejects_random() {
  run_spell spells/.imps/yes "maybe"
  assert_failure
}

# no tests
test_no_accepts_n() {
  run_spell spells/.imps/no "n"
  assert_success
}

test_no_accepts_N() {
  run_spell spells/.imps/no "N"
  assert_success
}

test_no_accepts_no() {
  run_spell spells/.imps/no "no"
  assert_success
}

test_no_accepts_NO() {
  run_spell spells/.imps/no "NO"
  assert_success
}

test_no_accepts_false() {
  run_spell spells/.imps/no "false"
  assert_success
}

test_no_accepts_FALSE() {
  run_spell spells/.imps/no "FALSE"
  assert_success
}

test_no_accepts_0() {
  run_spell spells/.imps/no "0"
  assert_success
}

test_no_rejects_yes() {
  run_spell spells/.imps/no "yes"
  assert_failure
}

test_no_rejects_empty() {
  run_spell spells/.imps/no ""
  assert_failure
}

test_no_rejects_random() {
  run_spell spells/.imps/no "maybe"
  assert_failure
}

run_test_case "contains finds substring" test_contains_finds_substring
run_test_case "contains rejects missing substring" test_contains_rejects_missing
run_test_case "starts matches prefix" test_starts_with
run_test_case "starts rejects non-prefix" test_starts_not
run_test_case "ends matches suffix" test_ends_with
run_test_case "ends rejects non-suffix" test_ends_not
run_test_case "say outputs to stdout" test_say_outputs
run_test_case "warn outputs to stderr" test_warn_to_stderr
run_test_case "yes affirms y" test_yes_affirms
run_test_case "yes affirms Y" test_yes_affirms_Y
run_test_case "yes affirms yes" test_yes_affirms_yes
run_test_case "yes affirms YES" test_yes_affirms_YES
run_test_case "yes affirms true" test_yes_affirms_true
run_test_case "yes affirms TRUE" test_yes_affirms_TRUE
run_test_case "yes affirms 1" test_yes_affirms_1
run_test_case "yes rejects no" test_yes_rejects_no
run_test_case "yes rejects empty" test_yes_rejects_empty
run_test_case "yes rejects random" test_yes_rejects_random
run_test_case "no accepts n" test_no_accepts_n
run_test_case "no accepts N" test_no_accepts_N
run_test_case "no accepts no" test_no_accepts_no
run_test_case "no accepts NO" test_no_accepts_NO
run_test_case "no accepts false" test_no_accepts_false
run_test_case "no accepts FALSE" test_no_accepts_FALSE
run_test_case "no accepts 0" test_no_accepts_0
run_test_case "no rejects yes" test_no_rejects_yes
run_test_case "no rejects empty" test_no_rejects_empty
run_test_case "no rejects random" test_no_rejects_random

finish_tests
