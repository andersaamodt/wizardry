#!/bin/sh
# Behavioral cases (derived from --help):
# - scribe-spell prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/scribe-spell" --help
  assert_success && assert_error_contains "Usage: scribe-spell"
}

run_test_case "scribe-spell prints usage" test_help
finish_tests
