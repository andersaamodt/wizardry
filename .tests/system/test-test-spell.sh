#!/bin/sh

# Test test-spell functionality

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/system/test-spell" --help
  _assert_success && _assert_output_contains "Usage:"
}

test_runs_full_test() {
  # Run a simple test fully
  _run_spell "spells/system/test-spell" "cantrips/test-ask-yn.sh"
  _assert_success
  _assert_output_contains "tests passed"
}

test_runs_single_subtest() {
  # Run just subtest #1
  _run_spell "spells/system/test-spell" "cantrips/test-ask-yn.sh" "1"
  _assert_success
  _assert_output_contains "PASS #1"
  # Should show exactly 1/1 tests passed
  _assert_output_contains "1/1 tests passed"
}

test_runs_multiple_subtests() {
  # Run subtests #1 and #2
  _run_spell "spells/system/test-spell" "cantrips/test-ask-yn.sh" "1" "2"
  _assert_success
  _assert_output_contains "PASS #1"
  _assert_output_contains "PASS #2"
  # Should show exactly 2/2 tests passed
  _assert_output_contains "2/2 tests passed"
}

test_missing_test_file() {
  # Should fail when test file doesn't exist
  _run_spell "spells/system/test-spell" "nonexistent/test-fake.sh"
  _assert_failure
  _assert_error_contains "not found"
}

test_requires_test_path() {
  # Should fail when no arguments provided
  _run_spell "spells/system/test-spell"
  _assert_failure
  _assert_error_contains "Usage:"
}

_run_test_case "test-spell shows usage" test_help
_run_test_case "test-spell runs full test" test_runs_full_test
_run_test_case "test-spell runs single subtest" test_runs_single_subtest
_run_test_case "test-spell runs multiple subtests" test_runs_multiple_subtests
_run_test_case "test-spell fails on missing test file" test_missing_test_file
_run_test_case "test-spell requires test path argument" test_requires_test_path

_finish_tests
