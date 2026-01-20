#!/bin/sh
# Tests for toggle-avatar - Toggle avatar system

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/mud/toggle-avatar" --help
  assert_success && assert_output_contains "Usage: toggle-avatar"
}

test_enable_avatar() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Enable avatar
  run_spell "spells/.arcana/mud/toggle-avatar" enable
  assert_success || return 1
  assert_output_contains "incarnate" || return 1
  
  # Verify config was set (.mud is a file)
  config_file="$SPELLBOOK_DIR/.mud/config"
  if [ -f "$config_file" ]; then
    value=$(grep "^avatar=" "$config_file" | cut -d= -f2)
    [ "$value" = "1" ] || { TEST_FAILURE_REASON="Expected avatar=1, got: $value"; return 1; }
  else
    TEST_FAILURE_REASON="Config file not created"
    return 1
  fi
}

test_disable_avatar() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Set initial state to enabled
  printf 'avatar=1\navatar-enabled=1\n' > "$SPELLBOOK_DIR/.mud/config"
  
  # Disable avatar
  run_spell "spells/.arcana/mud/toggle-avatar" disable
  assert_success || return 1
  assert_output_contains "disabled" || return 1
  
  # Verify config was updated
  config_file="$SPELLBOOK_DIR/.mud/config"
  value=$(grep "^avatar=" "$config_file" | cut -d= -f2)
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="Expected avatar=0, got: $value"; return 1; }
}

test_toggle_avatar() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # First toggle - enable (from default disabled)
  run_spell "spells/.arcana/mud/toggle-avatar"
  assert_success || return 1
  
  # Second toggle - disable
  run_spell "spells/.arcana/mud/toggle-avatar"
  assert_success || return 1
  assert_output_contains "disabled" || return 1
  
  # Verify we're disabled
  config_file="$SPELLBOOK_DIR/.mud/config"
  value=$(grep "^avatar=" "$config_file" | cut -d= -f2)
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="Expected avatar=0 after toggle, got: $value"; return 1; }
}

run_test_case "toggle-avatar prints usage" test_help
run_test_case "toggle-avatar enables avatar system" test_enable_avatar
run_test_case "toggle-avatar disables avatar system" test_disable_avatar
run_test_case "toggle-avatar toggles state" test_toggle_avatar

finish_tests
