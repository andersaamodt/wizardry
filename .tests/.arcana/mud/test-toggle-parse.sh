#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_sourced_spell "spells/.arcana/mud/toggle-parse" --help
  assert_success && assert_output_contains "Usage:"
}

test_toggle_enables_parse() {
  skip-if-compiled || return $?
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  assert_success
}

test_toggle_disables_parse() {
  skip-if-compiled || return $?
  # Enable first
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  # Then disable
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  assert_success
}

run_test_case "toggle-parse prints usage" test_help
run_test_case "toggle-parse enables parse" test_toggle_enables_parse
run_test_case "toggle-parse disables parse" test_toggle_disables_parse

finish_tests
