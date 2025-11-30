#!/bin/sh
# Tests for toggle-all-mud - Enable/disable all MUD features at once

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help_shows_usage() {
  run_spell "spells/install/mud/toggle-all-mud" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "--enable" || return 1
  assert_output_contains "--disable" || return 1
}

test_enable_flag_enables_all() {
  tmp=$(make_tempdir)
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud" --enable
  assert_success || return 1
  assert_output_contains "All MUD features enabled" || return 1
  
  # Verify all features are enabled
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/mud-config" list
  assert_success || return 1
  assert_output_contains "command-not-found=1" || return 1
  assert_output_contains "touch-hook=1" || return 1
  assert_output_contains "fantasy-theme=1" || return 1
  assert_output_contains "inventory=1" || return 1
  assert_output_contains "combat=1" || return 1
}

test_disable_flag_disables_all() {
  tmp=$(make_tempdir)
  # First enable all features
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud" --enable
  assert_success || return 1
  
  # Then disable all
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud" --disable
  assert_success || return 1
  assert_output_contains "All MUD features disabled" || return 1
  
  # Verify all features are disabled
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/mud-config" list
  assert_success || return 1
  assert_output_contains "command-not-found=0" || return 1
  assert_output_contains "touch-hook=0" || return 1
  assert_output_contains "fantasy-theme=0" || return 1
  assert_output_contains "inventory=0" || return 1
  assert_output_contains "combat=0" || return 1
}

test_auto_toggle_enables_when_any_disabled() {
  tmp=$(make_tempdir)
  # Start with all disabled (default state)
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud"
  assert_success || return 1
  assert_output_contains "All MUD features enabled" || return 1
}

test_auto_toggle_disables_when_all_enabled() {
  tmp=$(make_tempdir)
  # First enable all
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud" --enable
  assert_success || return 1
  
  # Auto-toggle should disable
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-all-mud"
  assert_success || return 1
  assert_output_contains "All MUD features disabled" || return 1
}

run_test_case "toggle-all-mud --help shows usage" test_help_shows_usage
run_test_case "toggle-all-mud --enable enables all features" test_enable_flag_enables_all
run_test_case "toggle-all-mud --disable disables all features" test_disable_flag_disables_all
run_test_case "toggle-all-mud auto-enables when any disabled" test_auto_toggle_enables_when_any_disabled
run_test_case "toggle-all-mud auto-disables when all enabled" test_auto_toggle_disables_when_all_enabled

finish_tests
