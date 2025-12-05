#!/bin/sh
# Tests for the 'assert-output-contains' imp

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_assert_output_contains_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/assert-output-contains" ]
}

test_assert_output_contains_succeeds_when_found() {
  run_spell spells/.imps/test/assert-output-contains "hello world" "world"
  assert_success
}

test_assert_output_contains_fails_when_missing() {
  run_spell spells/.imps/test/assert-output-contains "hello world" "missing"
  assert_failure
}

run_test_case "assert-output-contains is executable" test_assert_output_contains_exists
run_test_case "assert-output-contains succeeds when substring found" test_assert_output_contains_succeeds_when_found
run_test_case "assert-output-contains fails when substring missing" test_assert_output_contains_fails_when_missing

finish_tests
