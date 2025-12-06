#!/bin/sh
# Tests for the 'is-posint' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_is_posint_positive() {
  _run_spell spells/.imps/cond/is-posint 42
  _assert_success
}

test_is_posint_one() {
  _run_spell spells/.imps/cond/is-posint 1
  _assert_success
}

test_is_posint_fails_for_zero() {
  _run_spell spells/.imps/cond/is-posint 0
  _assert_failure
}

test_is_posint_fails_for_negative() {
  _run_spell spells/.imps/cond/is-posint -42
  _assert_failure
}

test_is_posint_fails_for_empty() {
  _run_spell spells/.imps/cond/is-posint ""
  _assert_failure
}

test_is_posint_fails_for_text() {
  _run_spell spells/.imps/cond/is-posint "abc"
  _assert_failure
}

test_is_posint_fails_for_float() {
  _run_spell spells/.imps/cond/is-posint "3.14"
  _assert_failure
}

test_is_posint_fails_for_mixed() {
  _run_spell spells/.imps/cond/is-posint "42abc"
  _assert_failure
}

_run_test_case "is-posint succeeds for positive" test_is_posint_positive
_run_test_case "is-posint succeeds for 1" test_is_posint_one
_run_test_case "is-posint fails for zero" test_is_posint_fails_for_zero
_run_test_case "is-posint fails for negative" test_is_posint_fails_for_negative
_run_test_case "is-posint fails for empty" test_is_posint_fails_for_empty
_run_test_case "is-posint fails for text" test_is_posint_fails_for_text
_run_test_case "is-posint fails for float" test_is_posint_fails_for_float
_run_test_case "is-posint fails for mixed" test_is_posint_fails_for_mixed

_finish_tests
