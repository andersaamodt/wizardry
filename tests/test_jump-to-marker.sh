#!/bin/sh
# Behavioral cases (derived from --help):
# - jump-to-marker prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/jump-to-marker" --help
  assert_success && assert_output_contains "Usage: jump-to-marker"
}

run_test_case "jump-to-marker prints usage" test_help
finish_tests
