#!/bin/sh
# Test coverage for add-ssh-player spell:
# - Shows usage with --help
# - Is POSIX compliant

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/menu/mud-admin/add-ssh-player" --help
  assert_success || return 1
  assert_output_contains "Usage: add-ssh-player" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/mud-admin/add-ssh-player" -h
  assert_success || return 1
  assert_output_contains "Usage: add-ssh-player" || return 1
}

test_has_strict_mode() {
  # Verify the spell uses strict mode
  grep -q "set -eu" "$ROOT_DIR/spells/menu/mud-admin/add-ssh-player" || {
    TEST_FAILURE_REASON="spell does not use strict mode"
    return 1
  }
}

run_test_case "add-ssh-player shows usage text" test_help
run_test_case "add-ssh-player shows usage with -h" test_help_h_flag
run_test_case "add-ssh-player uses strict mode" test_has_strict_mode


# Test via source-then-invoke pattern  

finish_tests
