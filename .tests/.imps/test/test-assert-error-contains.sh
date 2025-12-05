#!/bin/sh
# Tests for the 'assert-error-contains' imp

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_assert_error_contains_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/assert-error-contains" ]
}

test_assert_error_contains_succeeds_when_found() {
  run_spell spells/.imps/test/assert-error-contains "error message" "message"
  assert_success
}

test_assert_error_contains_fails_when_missing() {
  run_spell spells/.imps/test/assert-error-contains "error message" "missing"
  assert_failure
}

run_test_case "assert-error-contains is executable" test_assert_error_contains_exists
run_test_case "assert-error-contains succeeds when substring found" test_assert_error_contains_succeeds_when_found
run_test_case "assert-error-contains fails when substring missing" test_assert_error_contains_fails_when_missing

finish_tests
