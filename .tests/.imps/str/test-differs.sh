#!/bin/sh
# Tests for the 'differs' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_differs_different_strings() {
  run_spell spells/.imps/str/differs "hello" "world"
  assert_success
}

test_differs_same_string() {
  run_spell spells/.imps/str/differs "hello" "hello"
  assert_failure
}

run_test_case "differs accepts different strings" test_differs_different_strings
run_test_case "differs rejects same string" test_differs_same_string

finish_tests
