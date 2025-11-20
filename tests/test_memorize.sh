#!/bin/sh
# Behavioral cases (derived from --help):
# - memorize prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/memorize" --help
  assert_success && assert_output_contains "Usage:"
}

run_test_case "memorize prints usage" test_help
finish_tests
