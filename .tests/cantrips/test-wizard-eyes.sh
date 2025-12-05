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
  run_spell "spells/cantrips/wizard-eyes" --help
  assert_success || return 1
  assert_output_contains "Usage: wizard-eyes" || return 1
}

test_outputs_message() {
  WIZARD=1 run_spell "spells/cantrips/wizard-eyes" "test message"
  assert_success || return 1
  assert_output_contains "test message" || return 1
}

test_suppresses_when_disabled() {
  WIZARD=0 run_spell "spells/cantrips/wizard-eyes" "hidden message"
  assert_success || return 1
  # Output should be empty or not contain the message
  case "${OUTPUT-}" in
    *"hidden message"*)
      TEST_FAILURE_REASON="message should be suppressed when WIZARD=0"
      return 1
      ;;
  esac
}

run_test_case "wizard-eyes shows usage text" test_help
run_test_case "wizard-eyes outputs formatted message" test_outputs_message
run_test_case "wizard-eyes suppresses output when disabled" test_suppresses_when_disabled

finish_tests
