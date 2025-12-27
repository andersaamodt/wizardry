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

test_runs_full_test_with_common_by_default() {
  # Run a simple test fully - should include common tests by default
  _run_spell "spells/system/test-spell" "cantrips/test-ask-yn.sh"
  _assert_success
  _assert_output_contains "tests passed"
  # Should also show common test results by default
  _assert_output_contains "no duplicate spell names"
}

test_skip_common_flag_skips_common_tests() {
  # --skip-common should run only the test file, not common tests
  _run_spell "spells/system/test-spell" "--skip-common" "cantrips/test-ask-yn.sh"
  _assert_success
  _assert_output_contains "tests passed"
  # Should NOT show common test results when --skip-common is used
  if printf '%s' "$OUTPUT" | grep -q "no duplicate spell names"; then
    return 1
  fi
  return 0
}

test_runs_single_subtest() {
  # Run just subtest #1 - should skip common tests when filtering subtests
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

test_help_mentions_default_behavior() {
  # Help text should mention that common tests run by default
  _run_spell "spells/system/test-spell" "--help"
  _assert_success
  _assert_output_contains "By default"
  _assert_output_contains "For AI"
}

_run_test_case "test-spell shows usage" test_help
_run_test_case "test-spell runs with common tests by default" test_runs_full_test_with_common_by_default
_run_test_case "test-spell --skip-common skips common tests" test_skip_common_flag_skips_common_tests
_run_test_case "test-spell runs single subtest" test_runs_single_subtest
_run_test_case "test-spell runs multiple subtests" test_runs_multiple_subtests
_run_test_case "test-spell fails on missing test file" test_missing_test_file
_run_test_case "test-spell requires test path argument" test_requires_test_path
_run_test_case "test-spell help mentions default behavior" test_help_mentions_default_behavior


# Test via source-then-invoke pattern  
