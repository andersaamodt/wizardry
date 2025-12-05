#!/bin/sh
# Tests for the 'equals' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_equals_same_string() {
  run_spell spells/.imps/str/equals "hello" "hello"
  assert_success
}

test_equals_different_strings() {
  run_spell spells/.imps/str/equals "hello" "world"
  assert_failure
}

run_test_case "equals accepts same string" test_equals_same_string
run_test_case "equals rejects different strings" test_equals_different_strings

finish_tests
