#!/bin/sh
# Test coverage for new-player spell:
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
  _run_spell "spells/menu/mud-admin/new-player" --help
  _assert_success || return 1
  _assert_output_contains "Usage: new-player" || return 1
}

test_help_h_flag() {
  _run_spell "spells/menu/mud-admin/new-player" -h
  _assert_success || return 1
  _assert_output_contains "Usage: new-player" || return 1
}

test_has_strict_mode() {
  # Verify the spell uses strict mode
  grep -q "set -eu" "$ROOT_DIR/spells/menu/mud-admin/new-player" || {
    TEST_FAILURE_REASON="spell does not use strict mode"
    return 1
  }
}

_run_test_case "new-player shows usage text" test_help
_run_test_case "new-player shows usage with -h" test_help_h_flag
_run_test_case "new-player uses strict mode" test_has_strict_mode


# Test via source-then-invoke pattern  
new_player_help_via_sourcing() {
  _run_sourced_spell new-player --help
  _assert_success || return 1
  # Help text may go to stdout or stderr depending on spell
  if [ -n "$OUTPUT" ]; then
    case "$OUTPUT" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  if [ -n "$ERROR" ]; then
    case "$ERROR" in
      *Usage:*|*usage:*) return 0 ;;
    esac
  fi
  TEST_FAILURE_REASON="expected 'Usage:' in output or error"
  return 1
}

_run_test_case "new-player works via source-then-invoke" new_player_help_via_sourcing
_finish_tests
