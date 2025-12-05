#!/bin/sh
# Tests for the 'where' imp

# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_where_finds_command() {
  run_spell spells/.imps/sys/where sh
  assert_success
  [ -x "$OUTPUT" ] || { TEST_FAILURE_REASON="should output executable path"; return 1; }
}

test_where_fails_for_missing() {
  run_spell spells/.imps/sys/where nonexistent_command_xyz123
  assert_failure
}

run_test_case "where finds command" test_where_finds_command
run_test_case "where fails for missing command" test_where_fails_for_missing

finish_tests
