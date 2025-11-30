#!/bin/sh
# Tests for toggle-touch-hook - Toggle touch hook

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

test_help_shows_usage() {
  run_spell "spells/install/mud/toggle-touch-hook" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "touch hook" || return 1
}

test_toggle_enables_feature() {
  tmp=$(make_tempdir)
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-touch-hook"
  assert_success || return 1
  assert_output_contains "enabled" || return 1
}

test_toggle_disables_feature() {
  tmp=$(make_tempdir)
  # First enable
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-touch-hook"
  assert_success || return 1
  
  # Then disable
  run_cmd env WIZARDRY_MUD_CONFIG_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-touch-hook"
  assert_success || return 1
  assert_output_contains "disabled" || return 1
}

run_test_case "toggle-touch-hook --help shows usage" test_help_shows_usage
run_test_case "toggle-touch-hook enables feature" test_toggle_enables_feature
run_test_case "toggle-touch-hook toggles feature off" test_toggle_disables_feature

finish_tests
