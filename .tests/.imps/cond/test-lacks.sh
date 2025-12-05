#!/bin/sh
# Tests for the 'lacks' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_lacks_missing_command() {
  run_spell spells/.imps/cond/lacks nonexistent_command_xyz123
  assert_success
}

test_lacks_existing_command() {
  run_spell spells/.imps/cond/lacks sh
  assert_failure
}

run_test_case "lacks succeeds for missing command" test_lacks_missing_command
run_test_case "lacks fails for existing command" test_lacks_existing_command

finish_tests
