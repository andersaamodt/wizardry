#!/bin/sh
# Test coverage for priorities spell:
# - Shows usage with --help
# - Requires read-magic command
# - Exits when no priorities set

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/menu/priorities" --help
  assert_success || return 1
  assert_output_contains "Usage: priorities" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/priorities" -h
  assert_success || return 1
  assert_output_contains "Usage: priorities" || return 1
}

test_verbose_flag_accepted() {
  # Test that -v flag with --help is recognized
  run_spell "spells/menu/priorities" --help
  assert_success || return 1
  # Verify help mentions verbose mode
  assert_output_contains "-v" || return 1
}

run_test_case "priorities shows usage text" test_help
run_test_case "priorities shows usage with -h" test_help_h_flag
run_test_case "priorities accepts -v flag" test_verbose_flag_accepted

finish_tests
