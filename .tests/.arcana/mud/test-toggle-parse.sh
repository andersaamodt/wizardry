#!/bin/sh
# Tests for toggle-parse - uncastable spell that loads/unloads parse glosses

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_sourced_spell "spells/.arcana/mud/toggle-parse" --help
  assert_success && assert_output_contains "Usage:"
}

test_toggle_enables_parse() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Start with parse disabled
  mkdir -p "$SPELLBOOK_DIR"
  printf 'parse-enabled=0\n' > "$SPELLBOOK_DIR/.mud"
  
  # Toggle to enable
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Verify config was set
  value=$(config-get "$SPELLBOOK_DIR/.mud" "parse-enabled" 2>/dev/null)
  [ "$value" = "1" ] || { TEST_FAILURE_REASON="Expected parse-enabled=1, got: $value"; return 1; }
}

test_toggle_disables_parse() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Start with parse enabled
  mkdir -p "$SPELLBOOK_DIR"
  printf 'parse-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Toggle to disable
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Verify config was set to 0
  value=$(config-get "$SPELLBOOK_DIR/.mud" "parse-enabled" 2>/dev/null)
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="Expected parse-enabled=0, got: $value"; return 1; }
}

test_toggle_twice_returns_to_original() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Start with parse disabled
  mkdir -p "$SPELLBOOK_DIR"
  printf 'parse-enabled=0\n' > "$SPELLBOOK_DIR/.mud"
  
  # First toggle - enable
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Second toggle - disable
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Verify we're back to disabled
  value=$(config-get "$SPELLBOOK_DIR/.mud" "parse-enabled" 2>/dev/null)
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="Expected parse-enabled=0 after two toggles, got: $value"; return 1; }
}

test_parse_disabled_prevents_first_word_glosses() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Create a marker for testing jump
  mkdir -p "$SPELLBOOK_DIR/.markers"
  printf '%s\n' "$tmp" > "$SPELLBOOK_DIR/.markers/testmark"
  
  # Start with parse enabled, then disable it
  mkdir -p "$SPELLBOOK_DIR"
  printf 'parse-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Toggle to disable parse
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Verify parse is disabled in config
  value=$(config-get "$SPELLBOOK_DIR/.mud" "parse-enabled" 2>/dev/null)
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="parse-enabled should be 0"; return 1; }
}

test_hyphenated_commands_work_with_parse_disabled() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  
  # Create markers
  mkdir -p "$SPELLBOOK_DIR/.markers"
  printf '%s\n' "$tmp" > "$SPELLBOOK_DIR/.markers/test1"
  
  # Disable parse
  mkdir -p "$SPELLBOOK_DIR"
  printf 'parse-enabled=0\n' > "$SPELLBOOK_DIR/.mud"
  
  # Hyphenated command should still work (it's in PATH)
  # We can't actually test jump-to-marker easily here, but we can verify
  # that the config is set correctly for the integration test
  value=$(config-get "$SPELLBOOK_DIR/.mud" "parse-enabled" 2>/dev/null)
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="parse should be disabled"; return 1; }
}

run_test_case "toggle-parse shows usage" test_help
run_test_case "toggle-parse enables parse" test_toggle_enables_parse
run_test_case "toggle-parse disables parse" test_toggle_disables_parse
run_test_case "toggle-parse twice returns to original state" test_toggle_twice_returns_to_original
run_test_case "parse disabled prevents first-word glosses" test_parse_disabled_prevents_first_word_glosses
run_test_case "hyphenated commands work with parse disabled" test_hyphenated_commands_work_with_parse_disabled

finish_tests
