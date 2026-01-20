#!/bin/sh
# Tests for toggle-mud-menu - Toggle MUD visibility in main menu

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help_shows_usage() {
  run_spell "spells/.arcana/mud/toggle-mud-menu" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "MUD" || return 1
}

test_toggle_enables_when_initially_disabled() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Initially, mud-enabled should not be set (defaults to 0/disabled)
  run_spell "spells/.arcana/mud/toggle-mud-menu"
  assert_success || return 1
  assert_output_contains "enabled" || return 1
  
  # Verify the config was updated (.mud is a file, not a directory)
  config_file="$SPELLBOOK_DIR/.mud"
  if [ -f "$config_file" ]; then
    value=$(grep "^mud-enabled=" "$config_file" | cut -d= -f2)
    [ "$value" = "1" ] || { TEST_FAILURE_REASON="Expected mud-enabled=1, got: $value"; return 1; }
  else
    TEST_FAILURE_REASON="Config file not created at $config_file"
    return 1
  fi
}

test_toggle_disables_when_enabled() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Set initial state to enabled (.mud is a file)
  printf 'mud-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Toggle should disable
  run_spell "spells/.arcana/mud/toggle-mud-menu"
  assert_success || return 1
  assert_output_contains "hidden" || return 1
  
  # Verify the config was updated
  config_file="$SPELLBOOK_DIR/.mud"
  if [ -f "$config_file" ]; then
    value=$(grep "^mud-enabled=" "$config_file" | cut -d= -f2)
    [ "$value" = "0" ] || { TEST_FAILURE_REASON="Expected mud-enabled=0, got: $value"; return 1; }
  else
    TEST_FAILURE_REASON="Config file not found at $config_file"
    return 1
  fi
}

test_toggle_twice_returns_to_original_state() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # First toggle - enable
  run_spell "spells/.arcana/mud/toggle-mud-menu"
  assert_success || return 1
  assert_output_contains "enabled" || return 1
  
  # Second toggle - disable  
  run_spell "spells/.arcana/mud/toggle-mud-menu"
  assert_success || return 1
  assert_output_contains "hidden" || return 1
  
  # Verify we're back to disabled (.mud is a file)
  config_file="$SPELLBOOK_DIR/.mud"
  value=$(grep "^mud-enabled=" "$config_file" | cut -d= -f2)
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="Expected mud-enabled=0 after two toggles, got: $value"; return 1; }
}

test_creates_config_if_missing() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Don't create the .mud directory - let the script handle it
  run_spell "spells/.arcana/mud/toggle-mud-menu"
  assert_success || return 1
  
  # Verify config file was created
  config_file="$SPELLBOOK_DIR/.mud"
  [ -f "$config_file" ] || { TEST_FAILURE_REASON="Config file was not created"; return 1; }
}

run_test_case "toggle-mud-menu --help shows usage" test_help_shows_usage
run_test_case "toggle-mud-menu enables when initially disabled" test_toggle_enables_when_initially_disabled
run_test_case "toggle-mud-menu disables when enabled" test_toggle_disables_when_enabled
run_test_case "toggle-mud-menu twice returns to original state" test_toggle_twice_returns_to_original_state
run_test_case "toggle-mud-menu creates config if missing" test_creates_config_if_missing

finish_tests
