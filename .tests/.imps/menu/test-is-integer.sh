#!/bin/sh
# Tests for the 'is-integer' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_is_integer_positive() {
  _run_spell spells/.imps/menu/is-integer "42"
  _assert_success
}

test_is_integer_negative() {
  _run_spell spells/.imps/menu/is-integer "-5"
  _assert_success
}

test_is_integer_zero() {
  _run_spell spells/.imps/menu/is-integer "0"
  _assert_success
}

test_is_integer_rejects_float() {
  _run_spell spells/.imps/menu/is-integer "3.14"
  _assert_failure
}

test_is_integer_rejects_letters() {
  _run_spell spells/.imps/menu/is-integer "abc"
  _assert_failure
}

_run_test_case "is-integer accepts positive" test_is_integer_positive
_run_test_case "is-integer accepts negative" test_is_integer_negative
_run_test_case "is-integer accepts zero" test_is_integer_zero
_run_test_case "is-integer rejects float" test_is_integer_rejects_float
_run_test_case "is-integer rejects letters" test_is_integer_rejects_letters

_finish_tests
