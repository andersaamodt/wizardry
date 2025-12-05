#!/bin/sh
# Tests for toggle-fantasy-theme - Toggle fantasy theme

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help_shows_usage() {
  run_spell "spells/install/mud/toggle-fantasy-theme" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "fantasy theme" || return 1
}

test_toggle_enables_feature() {
  tmp=$(make_tempdir)
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-fantasy-theme"
  assert_success || return 1
  assert_output_contains "enabled" || return 1
}

test_toggle_disables_feature() {
  tmp=$(make_tempdir)
  # First enable
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-fantasy-theme"
  assert_success || return 1
  
  # Then disable
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-fantasy-theme"
  assert_success || return 1
  assert_output_contains "disabled" || return 1
}

test_fails_when_mud_config_missing() {
  tmp=$(make_tempdir)
  # Copy the toggle script to a temp location without mud-config
  cp "$ROOT_DIR/spells/install/mud/toggle-fantasy-theme" "$tmp/toggle-fantasy-theme"
  chmod +x "$tmp/toggle-fantasy-theme"
  
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$tmp/toggle-fantasy-theme"
  assert_failure || return 1
  assert_error_contains "mud-config not found" || return 1
}

run_test_case "toggle-fantasy-theme --help shows usage" test_help_shows_usage
run_test_case "toggle-fantasy-theme enables feature" test_toggle_enables_feature
run_test_case "toggle-fantasy-theme toggles feature off" test_toggle_disables_feature
run_test_case "toggle-fantasy-theme fails when mud-config missing" test_fails_when_mud_config_missing

finish_tests
