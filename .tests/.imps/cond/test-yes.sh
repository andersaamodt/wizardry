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
  run_spell spells/.imps/cond/yes "y"
  assert_success
}

test_yes_affirms_yes() {
  run_spell spells/.imps/cond/yes "yes"
  assert_success
}

test_yes_affirms_true() {
  run_spell spells/.imps/cond/yes "true"
  assert_success
}

test_yes_affirms_1() {
  run_spell spells/.imps/cond/yes "1"
  assert_success
}

test_yes_rejects_no() {
  run_spell spells/.imps/cond/yes "no"
  assert_failure
}

test_yes_rejects_empty() {
  run_spell spells/.imps/cond/yes ""
  assert_failure
}

run_test_case "yes affirms y" test_yes_affirms_y
run_test_case "yes affirms yes" test_yes_affirms_yes
run_test_case "yes affirms true" test_yes_affirms_true
run_test_case "yes affirms 1" test_yes_affirms_1
run_test_case "yes rejects no" test_yes_rejects_no
run_test_case "yes rejects empty" test_yes_rejects_empty

finish_tests
