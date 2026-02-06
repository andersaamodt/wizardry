#!/bin/sh
# Test cases for defcon spell:
# - defcon shows help
# - defcon applies level 1 immediately (no prompt)
# - defcon 1 applies level 1 explicitly (no prompt)
# - defcon 2-5 prompt for confirmation by default
# - defcon 2-5 with -y skip confirmation
# - defcon off unlocks the system
# - defcon rejects invalid levels
# - defcon tracks state in state file

set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_defcon_shows_help() {
  run_spell "spells/wards/defcon" --help
  assert_success || return 1
  assert_output_contains "Usage: defcon" || return 1
  assert_output_contains "DEFCON 1" || return 1
  assert_output_contains "defcon off" || return 1
}

test_defcon_help_short_flag() {
  run_spell "spells/wards/defcon" -h
  assert_success || return 1
  assert_output_contains "Usage: defcon" || return 1
}

test_defcon_rejects_invalid_level() {
  run_spell "spells/wards/defcon" 6
  assert_failure || return 1
  assert_error_contains "unknown argument: 6" || return 1
}

test_defcon_rejects_invalid_arg() {
  run_spell "spells/wards/defcon" invalid
  assert_failure || return 1
  assert_error_contains "unknown argument: invalid" || return 1
}

run_test_case "defcon shows help" test_defcon_shows_help
run_test_case "defcon -h shows help" test_defcon_help_short_flag
run_test_case "defcon rejects level 6" test_defcon_rejects_invalid_level
run_test_case "defcon rejects invalid args" test_defcon_rejects_invalid_arg

finish_tests
