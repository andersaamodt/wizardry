#!/bin/sh
# Test coverage for set-player spell:
# - Shows usage with --help
# - Requires player argument
# - Is POSIX compliant

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/menu/mud-admin/set-player" --help
  _assert_success || return 1
  _assert_output_contains "Usage: set-player" || return 1
}

test_requires_argument() {
  _run_spell "spells/menu/mud-admin/set-player"
  _assert_failure || return 1
  _assert_error_contains "player name required" || return 1
}

test_help_h_flag() {
  _run_spell "spells/menu/mud-admin/set-player" -h
  _assert_success || return 1
  _assert_output_contains "Usage: set-player" || return 1
}

_run_test_case "set-player shows usage text" test_help
_run_test_case "set-player requires player argument" test_requires_argument
_run_test_case "set-player shows usage with -h" test_help_h_flag

_finish_tests
