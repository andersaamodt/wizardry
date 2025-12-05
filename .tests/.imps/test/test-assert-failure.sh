#!/bin/sh
# Tests for the 'assert-failure' imp

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_assert_failure_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/assert-failure" ]
}

test_assert_failure_succeeds_on_nonzero() {
  run_spell spells/.imps/test/assert-failure 1
  assert_success
}

test_assert_failure_fails_on_zero() {
  run_spell spells/.imps/test/assert-failure 0
  assert_failure
}

run_test_case "assert-failure is executable" test_assert_failure_exists
run_test_case "assert-failure succeeds on non-zero status" test_assert_failure_succeeds_on_nonzero
run_test_case "assert-failure fails on status 0" test_assert_failure_fails_on_zero

finish_tests
