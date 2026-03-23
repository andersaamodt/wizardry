#!/bin/sh
# Test coverage for promote-admin spell:
# - Shows usage with --help and -h
# - Uses strict mode

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/menu/mud-admin/promote-admin" --help
  assert_success || return 1
  assert_output_contains "Usage: promote-admin" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/mud-admin/promote-admin" -h
  assert_success || return 1
  assert_output_contains "Usage: promote-admin" || return 1
}

test_has_strict_mode() {
  grep -q "set -eu" "$ROOT_DIR/spells/menu/mud-admin/promote-admin" || {
    TEST_FAILURE_REASON="spell does not use strict mode"
    return 1
  }
}

run_test_case "promote-admin shows usage text" test_help
run_test_case "promote-admin shows usage with -h" test_help_h_flag
run_test_case "promote-admin uses strict mode" test_has_strict_mode

finish_tests
