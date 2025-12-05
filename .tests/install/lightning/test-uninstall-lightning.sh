#!/bin/sh
set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/install/lightning/uninstall-lightning" ]
}
run_test_case "install/lightning/uninstall-lightning is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/install/lightning/uninstall-lightning" ]
}
run_test_case "install/lightning/uninstall-lightning has content" spell_has_content

shows_usage_help() {
  run_spell spells/install/lightning/uninstall-lightning --help
  assert_success || return 1
  assert_error_contains "Usage: uninstall-lightning"
}
run_test_case "uninstall-lightning shows usage help" shows_usage_help

removes_nixos_entry() {
  assert_file_contains "$ROOT_DIR/spells/install/lightning/uninstall-lightning" "nixos-rebuild"
}
run_test_case "uninstall-lightning cleans up nixos config" removes_nixos_entry

finish_tests
