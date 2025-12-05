#!/bin/sh
# Tests for toggle-combat - Toggle HP/MP and combat feature

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_help_shows_usage() {
  run_spell "spells/install/mud/toggle-combat" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "combat" || return 1
}

test_toggle_enables_feature() {
  tmp=$(make_tempdir)
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-combat"
  assert_success || return 1
  assert_output_contains "enabled" || return 1
}

test_toggle_disables_feature() {
  tmp=$(make_tempdir)
  # First enable
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-combat"
  assert_success || return 1
  
  # Then disable
  run_cmd env MUD_DIR="$tmp" "$ROOT_DIR/spells/install/mud/toggle-combat"
  assert_success || return 1
  assert_output_contains "disabled" || return 1
}

test_fails_when_mud_config_missing() {
  tmp=$(make_tempdir)
  # Copy the toggle script to a temp location without mud-config
  cp "$ROOT_DIR/spells/install/mud/toggle-combat" "$tmp/toggle-combat"
  chmod +x "$tmp/toggle-combat"
  
  run_cmd env MUD_DIR="$tmp" "$tmp/toggle-combat"
  assert_failure || return 1
  assert_error_contains "mud-config not found" || return 1
}

run_test_case "toggle-combat --help shows usage" test_help_shows_usage
run_test_case "toggle-combat enables feature" test_toggle_enables_feature
run_test_case "toggle-combat toggles feature off" test_toggle_disables_feature
run_test_case "toggle-combat fails when mud-config missing" test_fails_when_mud_config_missing

finish_tests
