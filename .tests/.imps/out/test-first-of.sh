#!/bin/sh
# Tests for the 'first-of' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_first_of_first() {
  run_spell spells/.imps/out/first-of "first" "second"
  assert_success
  assert_output_contains "first"
}

test_first_of_second() {
  run_spell spells/.imps/out/first-of "" "second"
  assert_success
  assert_output_contains "second"
}

test_first_of_fails_both_empty() {
  run_spell spells/.imps/out/first-of "" ""
  assert_failure
}

run_test_case "first-of returns first non-empty" test_first_of_first
run_test_case "first-of returns second if first empty" test_first_of_second
run_test_case "first-of fails if both empty" test_first_of_fails_both_empty

finish_tests
