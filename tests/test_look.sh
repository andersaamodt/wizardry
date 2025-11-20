#!/bin/sh
# Behavioral cases (derived from --help):
# - look prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/look" --help
  assert_success && assert_output_contains "Usage: look"
}

run_test_case "look prints usage" test_help
finish_tests
