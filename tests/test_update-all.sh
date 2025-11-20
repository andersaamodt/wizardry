#!/bin/sh
# Behavioral cases (derived from --help):
# - update-all prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/update-all" --help
  assert_success && assert_output_contains "Usage: update-all"
}

run_test_case "update-all prints usage" test_help
finish_tests
