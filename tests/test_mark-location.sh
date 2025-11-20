#!/bin/sh
# Behavioral cases (derived from --help):
# - mark-location prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/mark-location" --help
  assert_success && assert_output_contains "Usage: mark-location"
}

run_test_case "mark-location prints usage" test_help
finish_tests
