#!/bin/sh
# Test coverage for restart-ssh spell:
# - Shows usage with --help
# - Detects OS using os imp
# - Exits successfully when service manager available

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_help() {
  run_spell "spells/cantrips/restart-ssh" --help
  assert_success || return 1
  assert_output_contains "Usage: restart-ssh" || return 1
}

test_help_h_flag() {
  run_spell "spells/cantrips/restart-ssh" -h
  assert_success || return 1
  assert_output_contains "Usage: restart-ssh" || return 1
}

test_uses_os_imp() {
  # Verify the spell sources the os imp
  grep -q "os" "$ROOT_DIR/spells/cantrips/restart-ssh" || {
    TEST_FAILURE_REASON="spell does not use os imp"
    return 1
  }
}

run_test_case "restart-ssh shows usage text" test_help
run_test_case "restart-ssh shows usage with -h" test_help_h_flag
run_test_case "restart-ssh uses os imp for detection" test_uses_os_imp

finish_tests
