#!/bin/sh
# Behavioral cases (derived from --help):
# - detect-rc-file prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/detect-rc-file" --help
  assert_success && assert_error_contains "Usage: detect-rc-file"
}

run_test_case "detect-rc-file prints usage" test_help
finish_tests
