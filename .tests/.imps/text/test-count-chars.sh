#!/bin/sh
# Tests for the 'count-chars' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_count_chars_simple() {
  run_spell spells/.imps/text/count-chars "hello"
  assert_success
  assert_output_contains "5"
}

test_count_chars_empty() {
  run_spell spells/.imps/text/count-chars ""
  assert_success
  assert_output_contains "0"
}

run_test_case "count-chars counts simple string" test_count_chars_simple
run_test_case "count-chars handles empty" test_count_chars_empty

finish_tests
