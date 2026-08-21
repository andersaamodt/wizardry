#!/bin/sh
# Behavioral cases for parity:
# - shows help
# - defaults to the report
# - dispatches subcommands
# - rejects unknown commands

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

parity_shows_help() {
  run_spell "spells/spellcraft/parity" --help
  assert_success || return 1
  assert_output_contains "Usage: parity" || return 1
}

parity_defaults_to_report() {
  run_spell "spells/spellcraft/parity"
  assert_success || return 1
  assert_output_contains "Wizardry capability audit" || return 1
}

parity_dispatches_plan() {
  run_spell "spells/spellcraft/parity" plan android_termux
  assert_success || return 1
  assert_output_contains "android_termux / terminal_system" || return 1
}

parity_rejects_unknown_command() {
  run_spell "spells/spellcraft/parity" conjure
  assert_failure || return 1
  assert_error_contains "unknown command" || return 1
}

run_test_case "parity shows help" parity_shows_help
run_test_case "parity defaults to report" parity_defaults_to_report
run_test_case "parity dispatches plan" parity_dispatches_plan
run_test_case "parity rejects unknown command" parity_rejects_unknown_command

finish_tests
