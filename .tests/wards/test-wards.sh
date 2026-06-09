#!/bin/sh
# Behavioral cases for wards:
# - shows help
# - lists known wards
# - delegates ward checks

set -eu
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

wards_show_help() {
  run_spell "spells/wards/wards" --help
  assert_success || return 1
  assert_output_contains "Usage: wards" || return 1
}

wards_list_known_wards() {
  run_spell "spells/wards/wards"
  assert_success || return 1
  assert_output_contains "path-contained" || return 1
  assert_output_contains "status-row-safe" || return 1
}

wards_delegate_checks() {
  run_spell "spells/wards/wards" safe-label good-name
  assert_success || return 1
  run_spell "spells/wards/wards" safe-label ../bad
  assert_failure || return 1
}

run_test_case "wards shows help" wards_show_help
run_test_case "wards lists known wards" wards_list_known_wards
run_test_case "wards delegates checks" wards_delegate_checks

finish_tests
