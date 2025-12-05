#!/bin/sh
# Tests for toggle-mud-menu - Toggle MUD visibility in main menu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help_shows_usage() {
  run_spell "spells/install/mud/toggle-mud-menu" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "MUD" || return 1
}

test_toggle_enables_mud_menu() {
  tmp=$(make_tempdir)
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-mud-menu"
  assert_success || return 1
  assert_output_contains "enabled" || return 1
}

test_toggle_disables_mud_menu() {
  tmp=$(make_tempdir)
  # First enable
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-mud-menu"
  assert_success || return 1
  
  # Then disable
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-mud-menu"
  assert_success || return 1
  assert_output_contains "hidden" || return 1
}

test_fails_when_mud_config_missing() {
  tmp=$(make_tempdir)
  # Copy the toggle script to a temp location without mud-config
  cp "$ROOT_DIR/spells/install/mud/toggle-mud-menu" "$tmp/toggle-mud-menu"
  chmod +x "$tmp/toggle-mud-menu"
  
  run_cmd env MUD_DIR="$tmp" "$tmp/toggle-mud-menu"
  assert_failure || return 1
  assert_error_contains "mud-config not found" || return 1
}

run_test_case "toggle-mud-menu --help shows usage" test_help_shows_usage
run_test_case "toggle-mud-menu enables MUD in main menu" test_toggle_enables_mud_menu
run_test_case "toggle-mud-menu toggles MUD off" test_toggle_disables_mud_menu
run_test_case "toggle-mud-menu fails when mud-config missing" test_fails_when_mud_config_missing

finish_tests
