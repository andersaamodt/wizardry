#!/bin/sh
# Behavioral cases (derived from --help):
# - read-magic prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/read-magic" --help
  assert_success && assert_output_contains "Usage: read-magic"
}

run_test_case "read-magic prints usage" test_help
finish_tests
