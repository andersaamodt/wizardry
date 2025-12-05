#!/bin/sh
# Tests for the 'nonempty' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_nonempty_succeeds_for_nonempty() {
  run_spell spells/.imps/cond/nonempty "something"
  assert_success
}

test_nonempty_fails_for_empty() {
  run_spell spells/.imps/cond/nonempty ""
  assert_failure
}

run_test_case "nonempty succeeds for non-empty string" test_nonempty_succeeds_for_nonempty
run_test_case "nonempty fails for empty string" test_nonempty_fails_for_empty

finish_tests
