#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/lightning/lightning-menu" ]
}
run_test_case "install/lightning/lightning-menu is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/lightning/lightning-menu" ]
}
run_test_case "install/lightning/lightning-menu has content" spell_has_content

shows_usage_help() {
  run_spell spells/.arcana/lightning/lightning-menu --help
  assert_success || return 1
  assert_output_contains "Usage: lightning-menu"
}
run_test_case "lightning-menu shows usage help" shows_usage_help

contains_uninstall_entry() {
  assert_file_contains "$ROOT_DIR/spells/.arcana/lightning/lightning-menu" "Uninstall Lightning"
}
run_test_case "lightning-menu includes uninstall entry" contains_uninstall_entry

finish_tests
