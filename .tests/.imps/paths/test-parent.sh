#!/bin/sh
# Tests for the 'parent' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_parent_extracts() {
  run_spell spells/.imps/paths/parent "/path/to/file.txt"
  assert_success
  assert_output_contains "/path/to"
}

test_parent_handles_simple_file() {
  run_spell spells/.imps/paths/parent "file.txt"
  assert_success
  assert_output_contains "."
}

run_test_case "parent extracts directory" test_parent_extracts
run_test_case "parent handles simple file" test_parent_handles_simple_file

finish_tests
