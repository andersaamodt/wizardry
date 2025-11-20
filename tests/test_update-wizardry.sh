#!/bin/sh
# Behavioral cases (derived from --help):
# - update-wizardry prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/update-wizardry" --help
  assert_success && assert_output_contains "Usage: update-wizardry"
}

run_test_case "update-wizardry prints usage" test_help
finish_tests
