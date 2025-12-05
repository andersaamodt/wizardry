#!/bin/sh
# Tests for the 'empty' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_empty_succeeds_for_empty() {
  run_spell spells/.imps/cond/empty ""
  assert_success
}

test_empty_fails_for_nonempty() {
  run_spell spells/.imps/cond/empty "something"
  assert_failure
}

run_test_case "empty succeeds for empty string" test_empty_succeeds_for_empty
run_test_case "empty fails for non-empty string" test_empty_fails_for_nonempty

finish_tests
