#!/bin/sh
# Test coverage for wizard-eyes spell:
# - Shows usage with --help
# - Outputs formatted text when WIZARD=1

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

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

run_test_case "wizard-eyes shows usage text" test_help
run_test_case "wizard-eyes outputs formatted message" test_outputs_message

finish_tests
