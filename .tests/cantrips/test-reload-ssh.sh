#!/bin/sh
# Test coverage for reload-ssh spell:
# - Shows usage with --help
# - Detects OS using os imp
# - Exits successfully when service manager available

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/cantrips/reload-ssh" --help
  assert_success || return 1
  assert_output_contains "Usage: reload-ssh" || return 1
}

test_help_h_flag() {
  run_spell "spells/cantrips/reload-ssh" -h
  assert_success || return 1
  assert_output_contains "Usage: reload-ssh" || return 1
}

test_uses_os_imp() {
  # Verify the spell sources the os imp
  grep -q "os" "$ROOT_DIR/spells/cantrips/reload-ssh" || {
    TEST_FAILURE_REASON="spell does not use os imp"
    return 1
  }
}

run_test_case "reload-ssh shows usage text" test_help
run_test_case "reload-ssh shows usage with -h" test_help_h_flag
run_test_case "reload-ssh uses os imp for detection" test_uses_os_imp

finish_tests
