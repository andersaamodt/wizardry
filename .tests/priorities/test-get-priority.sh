#!/bin/sh
# Test coverage for get-priority spell:
# - Shows usage with --help
# - Requires file argument
# - Fails on missing file

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_help() {
  run_spell "spells/priorities/get-priority" --help
  assert_success || return 1
  assert_output_contains "Usage: get-priority" || return 1
}

test_requires_argument() {
  run_spell "spells/priorities/get-priority"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/priorities/get-priority" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

run_test_case "get-priority shows usage text" test_help
run_test_case "get-priority requires file argument" test_requires_argument
run_test_case "get-priority fails on missing file" test_fails_on_missing_file

finish_tests
