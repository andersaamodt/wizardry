#!/bin/sh
# Behavioral cases (derived from --help):
# - yaml-to-enchantment prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/yaml-to-enchantment" --help
  assert_success && assert_output_contains "Usage: yaml-to-enchantment"
}

run_test_case "yaml-to-enchantment prints usage" test_help
finish_tests
