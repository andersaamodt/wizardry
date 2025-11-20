#!/bin/sh
# Behavioral cases (derived from --help):
# - hash prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/hash" --help
  assert_success && assert_output_contains "Usage: hash"
}

run_test_case "hash prints usage" test_help
finish_tests
