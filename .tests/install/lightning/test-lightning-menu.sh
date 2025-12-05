#!/bin/sh
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/lightning/lightning-menu" ]
}
run_test_case "install/lightning/lightning-menu is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/lightning/lightning-menu" ]
}
run_test_case "install/lightning/lightning-menu has content" spell_has_content

shows_usage_help() {
  run_spell spells/install/lightning/lightning-menu --help
  assert_success || return 1
  assert_output_contains "Usage: lightning-menu"
}
run_test_case "lightning-menu shows usage help" shows_usage_help

contains_uninstall_entry() {
  assert_file_contains "$ROOT_DIR/spells/install/lightning/lightning-menu" "Uninstall Lightning"
}
run_test_case "lightning-menu includes uninstall entry" contains_uninstall_entry

finish_tests
