#!/bin/sh
# Tests for the 'no' imp

. "${0%/*}/../../spells/.imps/test/test-bootstrap"

test_no_accepts_n() {
  run_spell spells/.imps/cond/no "n"
  assert_success
}

test_no_accepts_no() {
  run_spell spells/.imps/cond/no "no"
  assert_success
}

test_no_accepts_false() {
  run_spell spells/.imps/cond/no "false"
  assert_success
}

test_no_accepts_0() {
  run_spell spells/.imps/cond/no "0"
  assert_success
}

test_no_rejects_yes() {
  run_spell spells/.imps/cond/no "yes"
  assert_failure
}

test_no_rejects_empty() {
  run_spell spells/.imps/cond/no ""
  assert_failure
}

run_test_case "no accepts n" test_no_accepts_n
run_test_case "no accepts no" test_no_accepts_no
run_test_case "no accepts false" test_no_accepts_false
run_test_case "no accepts 0" test_no_accepts_0
run_test_case "no rejects yes" test_no_rejects_yes
run_test_case "no rejects empty" test_no_rejects_empty

finish_tests
