#!/bin/sh
# Tests for the 'quiet' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_quiet_suppresses_output() {
  run_spell spells/.imps/out/quiet echo "should be silent"
  assert_success
  # Output should be empty
  if [ -n "$OUTPUT" ]; then
    TEST_FAILURE_REASON="output should be empty"
    return 1
  fi
}

test_quiet_preserves_exit_status() {
  run_spell spells/.imps/out/quiet false
  assert_failure
}

run_test_case "quiet suppresses output" test_quiet_suppresses_output
run_test_case "quiet preserves exit status" test_quiet_preserves_exit_status

finish_tests
