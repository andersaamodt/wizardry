#!/bin/sh
# Behavioral cases (derived from --help):
# - mud prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/mud" --help
  assert_success && assert_output_contains "Usage: mud"
}

run_test_case "mud prints usage" test_help
finish_tests
