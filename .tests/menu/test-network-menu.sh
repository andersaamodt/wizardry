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

test_shows_help() {
  run_cmd "$ROOT_DIR/spells/menu/network-menu" --help
  assert_success
  assert_output_contains "Usage: network-menu"
}

run_test_case "network-menu --help shows usage" test_shows_help

finish_tests
