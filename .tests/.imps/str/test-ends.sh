#!/bin/sh
# Tests for the 'ends' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_ends_with() {
  run_spell spells/.imps/str/ends "hello world" "world"
  assert_success
}

test_ends_not() {
  run_spell spells/.imps/str/ends "hello world" "hello"
  assert_failure
}

run_test_case "ends matches suffix" test_ends_with
run_test_case "ends rejects non-suffix" test_ends_not

finish_tests
