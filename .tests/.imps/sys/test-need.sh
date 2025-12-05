#!/bin/sh
# Tests for the 'need' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
