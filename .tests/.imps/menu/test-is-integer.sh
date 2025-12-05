#!/bin/sh
# Tests for the 'is-integer' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_is_integer_positive() {
  run_spell spells/.imps/menu/is-integer "42"
  assert_success
}

test_is_integer_negative() {
  run_spell spells/.imps/menu/is-integer "-5"
  assert_success
}

test_is_integer_zero() {
  run_spell spells/.imps/menu/is-integer "0"
  assert_success
}

test_is_integer_rejects_float() {
  run_spell spells/.imps/menu/is-integer "3.14"
  assert_failure
}

test_is_integer_rejects_letters() {
  run_spell spells/.imps/menu/is-integer "abc"
  assert_failure
}

run_test_case "is-integer accepts positive" test_is_integer_positive
run_test_case "is-integer accepts negative" test_is_integer_negative
run_test_case "is-integer accepts zero" test_is_integer_zero
run_test_case "is-integer rejects float" test_is_integer_rejects_float
run_test_case "is-integer rejects letters" test_is_integer_rejects_letters

finish_tests
