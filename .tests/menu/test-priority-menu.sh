#!/bin/sh
# Test coverage for priority-menu spell:
# - Shows usage with --help
# - Requires file argument
# - Sources colors

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help() {
  run_spell "spells/menu/priority-menu" --help
  assert_success || return 1
  assert_output_contains "Usage: priority-menu" || return 1
}

test_requires_file_argument() {
  run_spell "spells/menu/priority-menu"
  assert_failure || return 1
  assert_error_contains "file argument required" || return 1
}

test_help_h_flag() {
  run_spell "spells/menu/priority-menu" -h
  assert_success || return 1
  assert_output_contains "Usage: priority-menu" || return 1
}

run_test_case "priority-menu shows usage text" test_help
run_test_case "priority-menu requires file argument" test_requires_file_argument
run_test_case "priority-menu shows usage with -h" test_help_h_flag

finish_tests
