#!/bin/sh
# Test coverage for prioritize spell:
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
  _run_spell "spells/priorities/prioritize" --help
  _assert_success || return 1
  _assert_output_contains "Usage: prioritize" || return 1
}

test_requires_argument() {
  _run_spell "spells/priorities/prioritize"
  _assert_failure || return 1
  _assert_error_contains "file path required" || return 1
}

test_fails_on_missing_file() {
  _run_spell "spells/priorities/prioritize" "/nonexistent/file.txt"
  _assert_failure || return 1
  _assert_error_contains "file not found" || return 1
}

_run_test_case "prioritize shows usage text" test_help
_run_test_case "prioritize requires file argument" test_requires_argument
_run_test_case "prioritize fails on missing file" test_fails_on_missing_file


# Test via source-then-invoke pattern  
