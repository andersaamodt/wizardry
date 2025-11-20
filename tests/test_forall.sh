#!/bin/sh
# Behavioral cases (derived from --help):
# - forall prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/forall" --help
  assert_success && assert_output_contains "Usage: forall"
}

run_test_case "forall prints usage" test_help
finish_tests
