#!/bin/sh
# Tests for the 'has' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_has_existing_command() {
  run_spell spells/.imps/cond/has sh
  assert_success
}

test_has_missing_command() {
  run_spell spells/.imps/cond/has nonexistent_command_xyz123
  assert_failure
}

run_test_case "has succeeds for existing command" test_has_existing_command
run_test_case "has fails for missing command" test_has_missing_command

finish_tests
