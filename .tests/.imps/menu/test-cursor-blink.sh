#!/bin/sh
# Behavioral cases (derived from --help):
# - cursor-blink enforces argument count
# - cursor-blink rejects unknown states
# - cursor-blink is a no-op on dumb terminals
# - cursor-blink prints ANSI codes for supported terminals

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

cursor_blink_requires_one_argument() {
  skip-if-compiled || return $?
  run_spell "spells/.imps/menu/cursor-blink"
  assert_failure || return 1
  assert_error_contains "cursor-blink:" || return 1
  assert_error_contains "expected 'on' or 'off'" || return 1
}

cursor_blink_handles_unknown_value() {
  skip-if-compiled || return $?
  run_cmd env TERM=xterm "$ROOT_DIR/spells/.imps/menu/cursor-blink" maybe
  assert_failure || return 1
  assert_error_contains "cursor-blink:" || return 1
  assert_error_contains "expected 'on' or 'off'" || return 1
}

cursor_blink_succeeds_silently_on_dumb_terminal() {
  run_cmd env TERM=dumb "$ROOT_DIR/spells/.imps/menu/cursor-blink" on
  assert_success || return 1
  [ -z "$OUTPUT" ] || { TEST_FAILURE_REASON="expected no output on dumb terminal"; return 1; }
}

cursor_blink_emits_escape_sequences() {
  run_cmd env TERM=xterm "$ROOT_DIR/spells/.imps/menu/cursor-blink" on
  assert_success || return 1
  expected_on=$(printf '\033[?25h')
  [ "$OUTPUT" = "$expected_on" ] || { TEST_FAILURE_REASON="unexpected output for on"; return 1; }

  run_cmd env TERM=xterm "$ROOT_DIR/spells/.imps/menu/cursor-blink" off
  assert_success || return 1
  expected_off=$(printf '\033[?25l')
  [ "$OUTPUT" = "$expected_off" ] || { TEST_FAILURE_REASON="unexpected output for off"; return 1; }
}

run_test_case "cursor-blink enforces argument count" cursor_blink_requires_one_argument
run_test_case "cursor-blink rejects unknown states" cursor_blink_handles_unknown_value
run_test_case "cursor-blink is a no-op on dumb terminals" cursor_blink_succeeds_silently_on_dumb_terminal
run_test_case "cursor-blink prints ANSI codes for supported terminals" cursor_blink_emits_escape_sequences

shows_help() {
  # Set TERM to ensure cursor-blink doesn't exit early on "dumb" terminals
  run_cmd env TERM=xterm "$ROOT_DIR/spells/.imps/menu/cursor-blink" --help
  # Help is printed via usage function (returns non-zero, output to stderr)
  # Check both stdout and stderr for the usage message
  combined="$OUTPUT$ERROR"
  case "$combined" in
    *cursor-blink*) return 0 ;;
    *Usage*) return 0 ;;
    *) TEST_FAILURE_REASON="help output missing Usage"; return 1 ;;
  esac
}

run_test_case "cursor-blink shows help" shows_help


# Test via source-then-invoke pattern  

finish_tests
