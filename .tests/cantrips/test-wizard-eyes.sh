#!/bin/sh
# Test coverage for wizard-eyes spell:
# - Shows usage with --help
# - Outputs formatted text when WIZARD=1
# - Suppresses output when WIZARD=0

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/cantrips/wizard-eyes" --help
  _assert_success || return 1
  _assert_output_contains "Usage: wizard-eyes" || return 1
}

test_outputs_message() {
  skip-if-compiled || return $?
  WIZARD=1 _run_spell "spells/cantrips/wizard-eyes" "test message"
  _assert_success || return 1
  _assert_output_contains "test message" || return 1
}

test_suppresses_when_disabled() {
  WIZARD=0 _run_spell "spells/cantrips/wizard-eyes" "hidden message"
  _assert_success || return 1
  # Output should be empty or not contain the message
  case "${OUTPUT-}" in
    *"hidden message"*)
      TEST_FAILURE_REASON="message should be suppressed when WIZARD=0"
      return 1
      ;;
  esac
}

_run_test_case "wizard-eyes shows usage text" test_help
_run_test_case "wizard-eyes outputs formatted message" test_outputs_message
_run_test_case "wizard-eyes suppresses output when disabled" test_suppresses_when_disabled


# Test via source-then-invoke pattern  
wizard_eyes_help_via_sourcing() {
  _run_sourced_spell wizard-eyes --help
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

_run_test_case "wizard-eyes works via source-then-invoke" wizard_eyes_help_via_sourcing
_finish_tests
