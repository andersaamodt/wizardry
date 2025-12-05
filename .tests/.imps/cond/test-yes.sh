#!/bin/sh
# Tests for the 'yes' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_yes_affirms_y() {
  _run_spell spells/.imps/cond/yes "y"
  _assert_success
}

test_yes_affirms_yes() {
  _run_spell spells/.imps/cond/yes "yes"
  _assert_success
}

test_yes_affirms_true() {
  _run_spell spells/.imps/cond/yes "true"
  _assert_success
}

test_yes_affirms_1() {
  _run_spell spells/.imps/cond/yes "1"
  _assert_success
}

test_yes_rejects_no() {
  _run_spell spells/.imps/cond/yes "no"
  _assert_failure
}

test_yes_rejects_empty() {
  _run_spell spells/.imps/cond/yes ""
  _assert_failure
}

_run_test_case "yes affirms y" test_yes_affirms_y
_run_test_case "yes affirms yes" test_yes_affirms_yes
_run_test_case "yes affirms true" test_yes_affirms_true
_run_test_case "yes affirms 1" test_yes_affirms_1
_run_test_case "yes rejects no" test_yes_rejects_no
_run_test_case "yes rejects empty" test_yes_rejects_empty

_finish_tests
