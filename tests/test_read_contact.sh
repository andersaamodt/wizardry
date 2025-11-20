#!/bin/sh
# Behavioral cases (derived from --help):
# - read-contact prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/read-contact" --help
  assert_success && assert_output_contains "Usage: read-contact"
}

run_test_case "read-contact prints usage" test_help
finish_tests
