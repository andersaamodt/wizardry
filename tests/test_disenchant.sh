#!/bin/sh
# Behavioral cases (derived from --help):
# - disenchant prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/disenchant" --help
  assert_success && assert_output_contains "Usage: disenchant"
}

run_test_case "disenchant prints usage" test_help
finish_tests
