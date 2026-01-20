#!/bin/sh
# Tests for toggle-touch-hook - Toggle touch hook

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help_shows_usage() {
  run_spell "spells/mud/toggle-touch-hook" --help
  assert_success || return 1
  assert_output_contains "Usage:" || return 1
  assert_output_contains "touch hook" || return 1
}

test_toggle_enables_feature() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # First toggle - enable
  run_spell "spells/mud/toggle-touch-hook"
  assert_success || return 1
  assert_output_contains "enabled" || return 1
  
  # Verify config (.mud is a file)
  config_file="$SPELLBOOK_DIR/.mud"
  if [ -f "$config_file" ]; then
    value=$(grep "^touch-hook=" "$config_file" | cut -d= -f2)
    [ "$value" = "1" ] || { TEST_FAILURE_REASON="Expected touch-hook=1, got: $value"; return 1; }
  else
    TEST_FAILURE_REASON="Config file not created"
    return 1
  fi
}

test_toggle_disables_feature() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Set initial state to enabled
  printf 'touch-hook=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Toggle should disable
  run_spell "spells/mud/toggle-touch-hook"
  assert_success || return 1
  assert_output_contains "disabled" || return 1
  
  # Verify config
  config_file="$SPELLBOOK_DIR/.mud"
  value=$(grep "^touch-hook=" "$config_file" | cut -d= -f2)
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="Expected touch-hook=0, got: $value"; return 1; }
}

test_toggle_twice_returns_to_original() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # First toggle - enable
  run_spell "spells/mud/toggle-touch-hook"
  assert_success || return 1
  
  # Second toggle - disable
  run_spell "spells/mud/toggle-touch-hook"
  assert_success || return 1
  
  # Verify we're back to disabled
  config_file="$SPELLBOOK_DIR/.mud"
  value=$(grep "^touch-hook=" "$config_file" | cut -d= -f2)
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="Expected touch-hook=0 after two toggles, got: $value"; return 1; }
}

run_test_case "toggle-touch-hook --help shows usage" test_help_shows_usage
run_test_case "toggle-touch-hook enables feature" test_toggle_enables_feature
run_test_case "toggle-touch-hook disables feature" test_toggle_disables_feature
run_test_case "toggle-touch-hook twice returns to original state" test_toggle_twice_returns_to_original

finish_tests
