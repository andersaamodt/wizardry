#!/bin/sh
# Tests for the 'contains' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_contains_finds_substring() {
  run_spell spells/.imps/str/contains "hello world" "wor"
  assert_success
}

test_contains_rejects_missing() {
  run_spell spells/.imps/str/contains "hello world" "xyz"
  assert_failure
}

run_test_case "contains finds substring" test_contains_finds_substring
run_test_case "contains rejects missing substring" test_contains_rejects_missing

finish_tests
