#!/bin/sh
# Behavioral cases (derived from --help):
# - enchantment-to-yaml prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/enchantment-to-yaml" --help
  assert_success && assert_output_contains "Usage: enchantment-to-yaml"
}

run_test_case "enchantment-to-yaml prints usage" test_help
finish_tests
