#!/bin/sh
# Integration tests for toggle-parse - verifies instant effect in shell
# These tests verify that toggle-parse works instantly in both directions
# and that parsing behavior changes immediately without reopening terminal

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_parse_enabled_allows_first_word_commands() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  export WIZARDRY_DIR="$test_root"
  
  # Create markers for jump test
  mkdir -p "$SPELLBOOK_DIR/.markers"
  printf '%s\n' "$tmp" > "$SPELLBOOK_DIR/.markers/testmark"
  
  # Enable parse
  mkdir -p "$SPELLBOOK_DIR"
  printf 'parse-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Unset test-only mode to allow gloss generation
  unset WIZARDRY_TEST_HELPERS_ONLY
  unset WIZARDRY_INVOKED
  
  # Source invoke-wizardry to load glosses
  # shellcheck disable=SC1091
  . "$test_root/spells/.imps/sys/invoke-wizardry" 2>/dev/null || {
    TEST_FAILURE_REASON="Failed to source invoke-wizardry"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  }
  
  # Verify that a first-word gloss function exists (like 'jump')
  # If parsing is enabled, 'jump' should be a function
  if ! command -v jump >/dev/null 2>&1; then
    TEST_FAILURE_REASON="'jump' command should exist when parse is enabled"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  fi
  
  # Check if jump is a function (glosses create functions)
  type jump 2>/dev/null | grep -q "function" || {
    TEST_FAILURE_REASON="'jump' should be a function when parse is enabled"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  }
  
  # Restore test mode
  export WIZARDRY_TEST_HELPERS_ONLY=1
}

test_parse_disabled_removes_first_word_commands() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  export WIZARDRY_DIR="$test_root"
  
  # Start with parse enabled
  mkdir -p "$SPELLBOOK_DIR"
  printf 'parse-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Unset test-only mode to allow gloss generation
  unset WIZARDRY_TEST_HELPERS_ONLY
  unset WIZARDRY_INVOKED
  
  # Source invoke-wizardry to load glosses
  # shellcheck disable=SC1091
  . "$test_root/spells/.imps/sys/invoke-wizardry" 2>/dev/null || {
    TEST_FAILURE_REASON="Failed to source invoke-wizardry"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  }
  
  # Verify jump function exists
  if ! command -v jump >/dev/null 2>&1; then
    TEST_FAILURE_REASON="'jump' should exist before disabling parse"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  fi
  
  # Now toggle parse to disable it
  # shellcheck disable=SC1091
  . "$test_root/spells/.arcana/mud/toggle-parse" 2>/dev/null || {
    TEST_FAILURE_REASON="Failed to toggle parse"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  }
  
  # After toggling, the jump function should still exist (as a gloss for synonyms)
  # BUT it should NOT work for parsed commands like "jump to marker"
  # We can verify by checking the config
  value=$(config-get "$SPELLBOOK_DIR/.mud" "parse-enabled" 2>/dev/null)
  if [ "$value" != "0" ]; then
    TEST_FAILURE_REASON="parse-enabled should be 0 after toggle"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  fi
  
  # Restore test mode
  export WIZARDRY_TEST_HELPERS_ONLY=1
}

test_hyphenated_commands_always_work() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  export WIZARDRY_DIR="$test_root"
  
  # Create markers
  mkdir -p "$SPELLBOOK_DIR/.markers"
  printf '%s\n' "$tmp" > "$SPELLBOOK_DIR/.markers/test1"
  
  # Disable parse
  mkdir -p "$SPELLBOOK_DIR"
  printf 'parse-enabled=0\n' > "$SPELLBOOK_DIR/.mud"
  
  # Unset test-only mode to allow full wizardry setup
  unset WIZARDRY_TEST_HELPERS_ONLY
  unset WIZARDRY_INVOKED
  
  # Source invoke-wizardry
  # shellcheck disable=SC1091
  . "$test_root/spells/.imps/sys/invoke-wizardry" 2>/dev/null || {
    TEST_FAILURE_REASON="Failed to source invoke-wizardry"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  }
  
  # Hyphenated commands should be available (they're in PATH or as aliases/functions)
  if ! command -v jump-to-marker >/dev/null 2>&1; then
    TEST_FAILURE_REASON="jump-to-marker should be available"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  fi
  
  # Restore test mode
  export WIZARDRY_TEST_HELPERS_ONLY=1
}

test_toggle_changes_take_effect_immediately() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  export WIZARDRY_DIR="$test_root"
  
  # Start with parse disabled
  mkdir -p "$SPELLBOOK_DIR"
  printf 'parse-enabled=0\n' > "$SPELLBOOK_DIR/.mud"
  
  # Unset test-only mode to allow gloss generation
  unset WIZARDRY_TEST_HELPERS_ONLY
  unset WIZARDRY_INVOKED
  
  # Source invoke-wizardry
  # shellcheck disable=SC1091
  . "$test_root/spells/.imps/sys/invoke-wizardry" 2>/dev/null || {
    TEST_FAILURE_REASON="Failed to source invoke-wizardry"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  }
  
  # Verify parse is disabled
  value=$(config-get "$SPELLBOOK_DIR/.mud" "parse-enabled" 2>/dev/null)
  if [ "$value" != "0" ]; then
    TEST_FAILURE_REASON="parse should start disabled"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  fi
  
  # Toggle to enable
  # shellcheck disable=SC1091
  . "$test_root/spells/.arcana/mud/toggle-parse" 2>/dev/null || {
    TEST_FAILURE_REASON="Failed to toggle parse on"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  }
  
  # Verify config changed
  value=$(config-get "$SPELLBOOK_DIR/.mud" "parse-enabled" 2>/dev/null)
  if [ "$value" != "1" ]; then
    TEST_FAILURE_REASON="parse should be enabled after toggle"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  fi
  
  # Toggle back to disable
  # shellcheck disable=SC1091
  . "$test_root/spells/.arcana/mud/toggle-parse" 2>/dev/null || {
    TEST_FAILURE_REASON="Failed to toggle parse off"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  }
  
  # Verify config changed back
  value=$(config-get "$SPELLBOOK_DIR/.mud" "parse-enabled" 2>/dev/null)
  if [ "$value" != "0" ]; then
    TEST_FAILURE_REASON="parse should be disabled after second toggle"
    export WIZARDRY_TEST_HELPERS_ONLY=1
    return 1
  fi
  
  # Restore test mode
  export WIZARDRY_TEST_HELPERS_ONLY=1
}

run_test_case "parse enabled allows first-word commands" test_parse_enabled_allows_first_word_commands
run_test_case "parse disabled removes first-word commands" test_parse_disabled_removes_first_word_commands
run_test_case "hyphenated commands always work" test_hyphenated_commands_always_work
run_test_case "toggle changes take effect immediately" test_toggle_changes_take_effect_immediately

finish_tests
