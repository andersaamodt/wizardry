#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/mud/toggle-parse" --help
  assert_success && assert_output_contains "Usage:"
}

test_toggle_enables_parse() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # First toggle - enable (from default disabled)
  run_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Verify config was set (.mud is a file)
  config_file="$SPELLBOOK_DIR/.mud/config"
  if [ -f "$config_file" ]; then
    value=$(grep "^parse-enabled=" "$config_file" | cut -d= -f2)
    [ "$value" = "1" ] || { TEST_FAILURE_REASON="Expected parse-enabled=1, got: $value"; return 1; }
  else
    TEST_FAILURE_REASON="Config file not created"
    return 1
  fi
}

test_toggle_disables_parse() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Set initial state to enabled
  mkdir -p "$SPELLBOOK_DIR/.mud"
  printf 'parse-enabled=1\n' > "$SPELLBOOK_DIR/.mud/config"
  
  # Toggle should disable
  run_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Verify config was updated
  config_file="$SPELLBOOK_DIR/.mud/config"
  value=$(grep "^parse-enabled=" "$config_file" | cut -d= -f2)
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="Expected parse-enabled=0, got: $value"; return 1; }
}

test_toggle_twice_returns_to_original() {
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # First toggle - enable
  run_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Second toggle - disable
  run_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Verify we're back to disabled
  config_file="$SPELLBOOK_DIR/.mud/config"
  value=$(grep "^parse-enabled=" "$config_file" | cut -d= -f2)
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="Expected parse-enabled=0 after two toggles, got: $value"; return 1; }
}

run_test_case "toggle-parse shows usage" test_help
run_test_case "toggle-parse enables parse" test_toggle_enables_parse
run_test_case "toggle-parse disables parse" test_toggle_disables_parse
run_test_case "toggle-parse twice returns to original state" test_toggle_twice_returns_to_original

finish_tests
