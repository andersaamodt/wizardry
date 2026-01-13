#!/bin/sh

# Test test-spell functionality

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.wizardry/test-spell" --help
  assert_success && assert_output_contains "Usage:"
}

test_runs_test_file_successfully() {
  # Run a simple test
  run_spell "spells/.wizardry/test-spell" "cantrips/test-ask-yn.sh"
  assert_success
  assert_output_contains "tests passed"
}

test_skip_common_flag_is_ignored() {
  # --skip-common flag is deprecated but accepted for compatibility
  run_spell "spells/.wizardry/test-spell" "--skip-common" "cantrips/test-ask-yn.sh"
  assert_success
  assert_output_contains "tests passed"
}

test_missing_test_file() {
  # Should fail when test file doesn't exist
  run_spell "spells/.wizardry/test-spell" "nonexistent/test-fake.sh"
  assert_failure
  assert_error_contains "not found"
}

test_requires_test_path() {
  # Should fail when no arguments provided
  run_spell "spells/.wizardry/test-spell"
  assert_failure
  assert_error_contains "Usage:"
}

test_help_mentions_behavior() {
  # Help text should mention behavior
  run_spell "spells/.wizardry/test-spell" "--help"
  assert_success
  assert_output_contains "For AI"
}

run_test_case "test-spell shows usage" test_help
run_test_case "test-spell runs test file successfully" test_runs_test_file_successfully
run_test_case "test-spell --skip-common flag is ignored" test_skip_common_flag_is_ignored
run_test_case "test-spell fails on missing test file" test_missing_test_file
run_test_case "test-spell requires test path argument" test_requires_test_path
run_test_case "test-spell help mentions behavior" test_help_mentions_behavior


# Test via source-then-invoke pattern  

finish_tests
