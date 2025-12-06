#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/.arcana/lightning/uninstall-lightning" ]
}
_run_test_case "install/lightning/uninstall-lightning is executable" spell_is_executable

spell_has_content() {
  [ -s "$ROOT_DIR/spells/.arcana/lightning/uninstall-lightning" ]
}
_run_test_case "install/lightning/uninstall-lightning has content" spell_has_content

shows_usage_help() {
  _run_spell spells/.arcana/lightning/uninstall-lightning --help
  _assert_success || return 1
  _assert_error_contains "Usage: uninstall-lightning"
}
_run_test_case "uninstall-lightning shows usage help" shows_usage_help

removes_nixos_entry() {
  _assert_file_contains "$ROOT_DIR/spells/.arcana/lightning/uninstall-lightning" "nixos-rebuild"
}
_run_test_case "uninstall-lightning cleans up nixos config" removes_nixos_entry

_finish_tests
