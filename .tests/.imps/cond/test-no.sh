#!/bin/sh
# Tests for the 'no' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_no_accepts_n() {
  _run_spell spells/.imps/cond/no "n"
  _assert_success
}

test_no_accepts_no() {
  _run_spell spells/.imps/cond/no "no"
  _assert_success
}

test_no_accepts_false() {
  _run_spell spells/.imps/cond/no "false"
  _assert_success
}

test_no_accepts_0() {
  _run_spell spells/.imps/cond/no "0"
  _assert_success
}

test_no_rejects_yes() {
  _run_spell spells/.imps/cond/no "yes"
  _assert_failure
}

test_no_rejects_empty() {
  _run_spell spells/.imps/cond/no ""
  _assert_failure
}

_run_test_case "no accepts n" test_no_accepts_n
_run_test_case "no accepts no" test_no_accepts_no
_run_test_case "no accepts false" test_no_accepts_false
_run_test_case "no accepts 0" test_no_accepts_0
_run_test_case "no rejects yes" test_no_rejects_yes
_run_test_case "no rejects empty" test_no_rejects_empty

_finish_tests
