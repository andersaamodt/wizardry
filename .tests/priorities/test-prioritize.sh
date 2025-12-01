#!/bin/sh
# Test coverage for prioritize spell:
# - Shows usage with --help
# - Requires file argument
# - Fails on missing file

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/priorities/prioritize" --help
  assert_success || return 1
  assert_output_contains "Usage: prioritize" || return 1
}

test_requires_argument() {
  run_spell "spells/priorities/prioritize"
  assert_failure || return 1
  assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  run_spell "spells/priorities/prioritize" "/nonexistent/file.txt"
  assert_failure || return 1
  assert_error_contains "file not found" || return 1
}

run_test_case "prioritize shows usage text" test_help
run_test_case "prioritize requires file argument" test_requires_argument
run_test_case "prioritize fails on missing file" test_fails_on_missing_file

finish_tests
