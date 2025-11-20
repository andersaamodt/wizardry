#!/bin/sh
# Behavioral cases (derived from --help):
# - kill-process prints usage

. "$(CDPATH= cd "$(dirname "$0")" && pwd)/lib/test_common.sh"

test_help() {
  run_spell "spells/kill-process" --help
  assert_success && assert_output_contains "Usage: kill-process"
}

run_test_case "kill-process prints usage" test_help
finish_tests
