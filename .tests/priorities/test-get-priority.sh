#!/bin/sh
# Test coverage for get-priority spell:
# - Shows usage with --help
# - Requires file argument
# - Fails on missing file

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

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


# Test via source-then-invoke pattern  

finish_tests
