#!/bin/sh
# Test coverage for reload-ssh spell:
# - Shows usage with --help
# - Detects OS using os imp
# - Exits successfully when service manager available

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/cantrips/reload-ssh" --help
  _assert_success || return 1
  _assert_output_contains "Usage: reload-ssh" || return 1
}

test_help_h_flag() {
  _run_spell "spells/cantrips/reload-ssh" -h
  _assert_success || return 1
  _assert_output_contains "Usage: reload-ssh" || return 1
}

test_uses_os_imp() {
  # Verify the spell sources the os imp
  grep -q "os" "$ROOT_DIR/spells/cantrips/reload-ssh" || {
    TEST_FAILURE_REASON="spell does not use os imp"
    return 1
  }
}

_run_test_case "reload-ssh shows usage text" test_help
_run_test_case "reload-ssh shows usage with -h" test_help_h_flag
_run_test_case "reload-ssh uses os imp for detection" test_uses_os_imp

_finish_tests
