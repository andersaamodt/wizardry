#!/bin/sh
# Behavioral cases (derived from --help):
# - hashchant prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/hashchant" --help
  assert_success && assert_output_contains "Usage: hashchant"
}

run_test_case "hashchant prints usage" test_help
finish_tests
