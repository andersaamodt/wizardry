#!/bin/sh
# Tests for the 'file-name' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_file_name_extracts() {
  run_spell spells/.imps/paths/file-name "/path/to/file.txt"
  assert_success
  assert_output_contains "file.txt"
}

test_file_name_handles_simple_name() {
  run_spell spells/.imps/paths/file-name "simple.txt"
  assert_success
  assert_output_contains "simple.txt"
}

run_test_case "file-name extracts filename" test_file_name_extracts
run_test_case "file-name handles simple name" test_file_name_handles_simple_name

finish_tests
