#!/bin/sh
# Behavioral cases (derived from --help):
# - path-wizard prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/path-wizard" --help
  assert_success && assert_error_contains "Usage: path-wizard"
}

run_test_case "path-wizard prints usage" test_help
finish_tests
