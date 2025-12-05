#!/bin/sh
# Tests for the 'yes' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
