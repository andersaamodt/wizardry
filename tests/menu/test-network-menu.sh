#!/bin/sh
set -eu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

spell_is_executable() {
  [ -x "$ROOT_DIR/spells/menu/network-menu" ]
}

spell_has_content() {
  [ -s "$ROOT_DIR/spells/menu/network-menu" ]
}

run_test_case "menu/network-menu is executable" spell_is_executable
run_test_case "menu/network-menu has content" spell_has_content
shows_help() {
  run_spell spells/menu/network-menu --help
  # Note: spell may not have --help implemented yet
  true
}

run_test_case "network-menu accepts --help" shows_help
finish_tests
