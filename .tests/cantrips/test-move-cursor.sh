#!/bin/sh
# Behavioral cases (derived from --help):
# - move-cursor enforces argument count
# - move-cursor validates numeric coordinates
# - move-cursor clamps coordinates and emits escape
# - move-cursor is a no-op on dumb terminals

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

move_cursor_requires_two_arguments() {
  _run_spell "spells/cantrips/move-cursor" 5
  _assert_failure || return 1
  _assert_error_contains "Usage: move-cursor" || return 1
}

move_cursor_rejects_non_numeric_coordinates() {
  _run_spell "spells/cantrips/move-cursor" abc 2
  _assert_failure || return 1
  _assert_error_contains "invalid column" || return 1

  _run_spell "spells/cantrips/move-cursor" 3 two
  _assert_failure || return 1
  _assert_error_contains "invalid row" || return 1
}

move_cursor_clamps_and_emits_escape_sequence() {
  _run_cmd env TERM=xterm "$ROOT_DIR/spells/cantrips/move-cursor" 0 0
  _assert_success || return 1
  expected=$(printf '\033[1;1H')
  [ "$OUTPUT" = "$expected" ] || { TEST_FAILURE_REASON="expected escape to row 1 col 1"; return 1; }
}

move_cursor_succeeds_quietly_on_dumb_terminal() {
  _run_cmd env TERM=dumb "$ROOT_DIR/spells/cantrips/move-cursor" 4 7
  _assert_success || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no output on dumb terminal"; return 1; }
}

_run_test_case "move-cursor enforces argument count" move_cursor_requires_two_arguments
_run_test_case "move-cursor validates numeric coordinates" move_cursor_rejects_non_numeric_coordinates
_run_test_case "move-cursor clamps coordinates and emits escape" move_cursor_clamps_and_emits_escape_sequence
_run_test_case "move-cursor is a no-op on dumb terminals" move_cursor_succeeds_quietly_on_dumb_terminal

shows_help() {
  _run_spell spells/cantrips/move-cursor --help
  # Help is printed via usage function (returns non-zero, output to stderr)
  _assert_error_contains "Usage:"
}

_run_test_case "move-cursor shows help" shows_help

_finish_tests
