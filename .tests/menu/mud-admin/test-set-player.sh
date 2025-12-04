#!/bin/sh
# Test coverage for set-player spell:
# - Shows usage with --help
# - Requires player argument
# - Is POSIX compliant

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/menu/mud-admin/set-player" --help
  assert_success || return 1
  assert_output_contains "Usage: set-player" || return 1
}

test_requires_argument() {
  run_spell "spells/menu/mud-admin/set-player"
  assert_failure || return 1
  assert_error_contains "player name required" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/mud-admin/set-player" -h
  assert_success || return 1
  assert_output_contains "Usage: set-player" || return 1
}

run_test_case "set-player shows usage text" test_help
run_test_case "set-player requires player argument" test_requires_argument
run_test_case "set-player shows usage with -h" test_help_h_flag

finish_tests
