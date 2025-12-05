#!/bin/sh
# Tests for the 'fail' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_fail_exits_with_message() {
  run_spell spells/.imps/out/fail "error message"
  assert_failure
  assert_error_contains "error message"
}

test_fail_exits_with_status_1() {
  run_spell spells/.imps/out/fail "test"
  [ "$STATUS" -eq 1 ] || { TEST_FAILURE_REASON="expected status 1, got $STATUS"; return 1; }
}

run_test_case "fail exits with message" test_fail_exits_with_message
run_test_case "fail exits with status 1" test_fail_exits_with_status_1

finish_tests
