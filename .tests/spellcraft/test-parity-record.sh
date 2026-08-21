#!/bin/sh
# Behavioral cases for parity-record:
# - shows help
# - emits one complete TSV record
# - rejects unknown capabilities and checks

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

parity_record_shows_help() {
  run_spell "spells/spellcraft/parity-record" --help
  assert_success || return 1
  assert_output_contains "Usage: parity-record" || return 1
}

parity_record_emits_tsv() {
  run_spell "spells/spellcraft/parity-record" terminal_system macos \
    automated_on_platform discoverable,installed,executable,outcome_passed \
    - receipt-42 "All checks passed"
  assert_success || return 1
  assert_output_contains "terminal_system" || return 1
  assert_output_contains "automated_on_platform" || return 1
  assert_output_contains "true	true	true	true" || return 1
  assert_output_contains "receipt-42" || return 1
}

parity_record_rejects_bad_input() {
  run_spell "spells/spellcraft/parity-record" imaginary macos simulated -
  assert_failure || return 1
  assert_error_contains "unknown capability" || return 1

  run_spell "spells/spellcraft/parity-record" terminal_system macos simulated impossible
  assert_failure || return 1
  assert_error_contains "unknown check" || return 1
}

run_test_case "parity-record shows help" parity_record_shows_help
run_test_case "parity-record emits TSV" parity_record_emits_tsv
run_test_case "parity-record rejects bad input" parity_record_rejects_bad_input

finish_tests
