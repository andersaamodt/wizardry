#!/bin/sh
# Tests for the 'assert-success' imp

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_assert_success_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/assert-success" ]
}

test_assert_success_succeeds_on_zero() {
  run_spell spells/.imps/test/assert-success 0 ""
  assert_success
}

test_assert_success_fails_on_nonzero() {
  run_spell spells/.imps/test/assert-success 1 ""
  assert_failure
}

run_test_case "assert-success is executable" test_assert_success_exists
run_test_case "assert-success succeeds on status 0" test_assert_success_succeeds_on_zero
run_test_case "assert-success fails on non-zero status" test_assert_success_fails_on_nonzero

finish_tests
