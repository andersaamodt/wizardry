#!/bin/sh
# Behavioral cases (derived from --help):
# - enchant prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/enchant" --help
  assert_success && assert_output_contains "Usage: enchant"
}

run_test_case "enchant prints usage" test_help
finish_tests
