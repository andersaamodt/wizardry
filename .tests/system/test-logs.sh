#!/bin/sh
# Test coverage for logs spell:
# - Shows usage with --help
# - Script exists and is executable
# - Sources required files

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_help() {
  run_spell "spells/system/logs" --help
  assert_success || return 1
  assert_output_contains "Usage: logs" || return 1
}

test_spell_exists() {
  [ -f "$ROOT_DIR/spells/system/logs" ] || { TEST_FAILURE_REASON="spell file does not exist"; return 1; }
}

test_is_executable() {
  [ -x "$ROOT_DIR/spells/system/logs" ] || { TEST_FAILURE_REASON="spell is not executable"; return 1; }
}

run_test_case "logs shows usage text" test_help
run_test_case "logs spell exists" test_spell_exists
run_test_case "logs spell is executable" test_is_executable

finish_tests
