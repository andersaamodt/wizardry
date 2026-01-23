#!/bin/sh
# Tests for toggle-cd - uncastable spell that loads/unloads cd hook

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_sourced_spell "spells/.arcana/mud/toggle-cd" --help
  assert_success && assert_output_contains "Usage:"
}

test_toggle_enables() {
  skip-if-compiled || return $?
  run_sourced_spell "spells/.arcana/mud/toggle-cd"
  assert_success
}

test_toggle_disables() {
  skip-if-compiled || return $?
  # Enable first
  run_sourced_spell "spells/.arcana/mud/toggle-cd"
  # Then disable
  run_sourced_spell "spells/.arcana/mud/toggle-cd"
  assert_success
}

run_test_case "toggle-cd prints usage" test_help
run_test_case "toggle-cd enables cd hook" test_toggle_enables
run_test_case "toggle-cd disables cd hook" test_toggle_disables

finish_tests
