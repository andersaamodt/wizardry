#!/bin/sh
# Tests for toggle-command-not-found - Toggle command-not-found hook feature

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help_shows_usage() {
  run_spell "spells/.arcana/mud/toggle-command-not-found" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "command-not-found" || return 1
}

test_toggle_enables_feature() {
  tmp=$(make_tempdir)
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found"
  assert_success || return 1
  assert_output_contains "enabled" || return 1
}

test_toggle_disables_feature() {
  tmp=$(make_tempdir)
  # First enable
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found"
  assert_success || return 1
  
  # Then disable
  run_cmd env SPELLBOOK_DIR="$tmp" "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found"
  assert_success || return 1
  assert_output_contains "disabled" || return 1
}

test_fails_when_mud_config_missing() {
  tmp=$(make_tempdir)
  # Copy the toggle script to a temp location without mud-config
  cp "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found" "$tmp/toggle-command-not-found"
  chmod +x "$tmp/toggle-command-not-found"
  
  run_cmd env MUD_DIR="$tmp" "$tmp/toggle-command-not-found"
  assert_failure || return 1
  assert_error_contains "mud-config not found" || return 1
}

run_test_case "toggle-command-not-found --help shows usage" test_help_shows_usage
run_test_case "toggle-command-not-found enables feature" test_toggle_enables_feature
run_test_case "toggle-command-not-found toggles feature off" test_toggle_disables_feature
run_test_case "toggle-command-not-found fails when mud-config missing" test_fails_when_mud_config_missing

finish_tests
