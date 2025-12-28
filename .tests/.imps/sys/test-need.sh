#!/bin/sh
# Tests for the 'need' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_need_existing_command() {
  run_spell spells/.imps/sys/need sh
  assert_success
}

test_need_missing_command() {
  run_spell spells/.imps/sys/need nonexistent_command_xyz123
  assert_failure
  assert_error_contains "nonexistent_command_xyz123"
}

test_need_custom_message() {
  run_spell spells/.imps/sys/need nonexistent_command_xyz123 "custom error message"
  assert_failure
  assert_error_contains "custom error message"
}

run_test_case "need succeeds for existing command" test_need_existing_command
run_test_case "need fails for missing command" test_need_missing_command
run_test_case "need shows custom message" test_need_custom_message

finish_tests
