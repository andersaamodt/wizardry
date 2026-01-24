#!/bin/sh
# Tests for toggle-parse - uncastable spell that loads/unloads gloss functions

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
  mkdir -p "$SPELLBOOK_DIR"
  
  # Set initial state to disabled
  printf 'parse-enabled=0\n' > "$SPELLBOOK_DIR/.mud"
  
  # Toggle should enable
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Verify config was set (.mud is a file)
  config_file="$SPELLBOOK_DIR/.mud"
  if [ -f "$config_file" ]; then
    value=$(grep "^parse-enabled=" "$config_file" | cut -d= -f2)
    test_msg="Expected parse-enabled=1, got: $value"
    [ "$value" = "1" ] || { TEST_FAILURE_REASON="$test_msg"; return 1; }
  else
    TEST_FAILURE_REASON="Config file not created"
    return 1
  fi
}

test_toggle_disables_parse() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  mkdir -p "$SPELLBOOK_DIR"
  
  # Set initial state to enabled
  printf 'parse-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Toggle should disable
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Verify config was updated
  config_file="$SPELLBOOK_DIR/.mud"
  value=$(grep "^parse-enabled=" "$config_file" | cut -d= -f2)
  test_msg="Expected parse-enabled=0, got: $value"
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="$test_msg"; return 1; }
}

test_toggle_twice_returns_to_original() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  mkdir -p "$SPELLBOOK_DIR"
  
  # Set initial state to disabled
  printf 'parse-enabled=0\n' > "$SPELLBOOK_DIR/.mud"
  
  # First toggle - enable
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Second toggle - disable
  run_sourced_spell "spells/.arcana/mud/toggle-parse"
  assert_success || return 1
  
  # Verify we're back to disabled
  config_file="$SPELLBOOK_DIR/.mud"
  value=$(grep "^parse-enabled=" "$config_file" | cut -d= -f2)
  test_msg="Expected parse-enabled=0 after two toggles, got: $value"
  [ "$value" = "0" ] || { TEST_FAILURE_REASON="$test_msg"; return 1; }
}

test_functions_unloaded_when_disabled() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  export WIZARDRY_DIR="$test_root"
  mkdir -p "$SPELLBOOK_DIR"
  
  # Start with parse enabled
  printf 'parse-enabled=1\n' > "$SPELLBOOK_DIR/.mud"
  
  # Temporarily allow gloss loading in test environment
  _old_test_mode="${WIZARDRY_TEST_HELPERS_ONLY-}"
  unset WIZARDRY_TEST_HELPERS_ONLY
  
  # Source invoke-wizardry to load gloss functions AND add imps to PATH
  unset WIZARDRY_INVOKED
  . "$test_root/spells/.imps/sys/invoke-wizardry" 2>/dev/null || true
  
  # Verify first-word gloss function exists (e.g., 'jump' function for 'jump-to-marker')
  if ! type jump >/dev/null 2>&1; then
    # Restore test mode before failing
    if [ -n "$_old_test_mode" ]; then
      WIZARDRY_TEST_HELPERS_ONLY="$_old_test_mode"
      export WIZARDRY_TEST_HELPERS_ONLY
    fi
    TEST_FAILURE_REASON="jump function not defined after enabling parse"
    return 1
  fi
  
  # Verify config-set is available (needed by toggle-parse)
  if ! command -v config-set >/dev/null 2>&1; then
    # Restore test mode before failing
    if [ -n "$_old_test_mode" ]; then
      WIZARDRY_TEST_HELPERS_ONLY="$_old_test_mode"
      export WIZARDRY_TEST_HELPERS_ONLY
    fi
    TEST_FAILURE_REASON="config-set not available after invoke-wizardry"
    return 1
  fi
  
  # Now disable parse by directly sourcing toggle-parse
  . "$test_root/spells/.arcana/mud/toggle-parse" 2>/dev/null || true
  
  # Restore test mode
  if [ -n "$_old_test_mode" ]; then
    WIZARDRY_TEST_HELPERS_ONLY="$_old_test_mode"
    export WIZARDRY_TEST_HELPERS_ONLY
  fi
  
  # Verify the first-word gloss function is no longer defined
  # After disabling parse, 'jump' should either not exist or be a synonym (not a first-word gloss)
  if type jump >/dev/null 2>&1; then
    # Check if it's a synonym by seeing if it calls jump-to-marker directly
    # A first-word gloss would route through 'parse', a synonym calls the spell directly
    func_body=$(type jump 2>&1 || true)
    case "$func_body" in
      *parse*"$@"*)
        TEST_FAILURE_REASON="jump function still routes through parse after disabling"
        return 1
        ;;
    esac
  fi
}

test_functions_loaded_when_enabled() {
  skip-if-compiled || return $?
  tmp=$(make_tempdir)
  export SPELLBOOK_DIR="$tmp"
  export WIZARDRY_DIR="$test_root"
  mkdir -p "$SPELLBOOK_DIR"
  
  # Start with parse disabled
  printf 'parse-enabled=0\n' > "$SPELLBOOK_DIR/.mud"
  
  # Temporarily allow gloss loading in test environment
  _old_test_mode="${WIZARDRY_TEST_HELPERS_ONLY-}"
  unset WIZARDRY_TEST_HELPERS_ONLY
  
  # Source invoke-wizardry (should NOT load first-word glosses but WILL add imps to PATH)
  unset WIZARDRY_INVOKED
  . "$test_root/spells/.imps/sys/invoke-wizardry" 2>/dev/null || true
  
  # Verify config-set is available (needed by toggle-parse)
  if ! command -v config-set >/dev/null 2>&1; then
    # Restore test mode before failing
    if [ -n "$_old_test_mode" ]; then
      WIZARDRY_TEST_HELPERS_ONLY="$_old_test_mode"
      export WIZARDRY_TEST_HELPERS_ONLY
    fi
    TEST_FAILURE_REASON="config-set not available after invoke-wizardry"
    return 1
  fi
  
  # Verify parse is disabled
  config_value=$(grep "^parse-enabled=" "$SPELLBOOK_DIR/.mud" | cut -d= -f2)
  if [ "$config_value" != "0" ]; then
    # Restore test mode before failing
    if [ -n "$_old_test_mode" ]; then
      WIZARDRY_TEST_HELPERS_ONLY="$_old_test_mode"
      export WIZARDRY_TEST_HELPERS_ONLY
    fi
    TEST_FAILURE_REASON="parse-enabled not 0 before toggle, got: $config_value"
    return 1
  fi
  
  # Now enable parse by directly sourcing toggle-parse
  . "$test_root/spells/.arcana/mud/toggle-parse" 2>/dev/null || true
  
  # Verify parse is now enabled
  config_value=$(grep "^parse-enabled=" "$SPELLBOOK_DIR/.mud" | cut -d= -f2)
  if [ "$config_value" != "1" ]; then
    # Restore test mode before failing
    if [ -n "$_old_test_mode" ]; then
      WIZARDRY_TEST_HELPERS_ONLY="$_old_test_mode"
      export WIZARDRY_TEST_HELPERS_ONLY
    fi
    TEST_FAILURE_REASON="parse-enabled not 1 after toggle, got: $config_value"
    return 1
  fi
  
  # Restore test mode
  if [ -n "$_old_test_mode" ]; then
    WIZARDRY_TEST_HELPERS_ONLY="$_old_test_mode"
    export WIZARDRY_TEST_HELPERS_ONLY
  fi
  
  # Verify first-word gloss function exists
  if ! type jump >/dev/null 2>&1 && ! command -v jump >/dev/null 2>&1; then
    TEST_FAILURE_REASON="jump function not defined after enabling parse"
    return 1
  fi
  
  # Check cache file for parse routing (more reliable than type output)
  cache_dir="${TMPDIR:-/tmp}"
  cache_dir="${cache_dir%/}"
  cache_id=$(printf '%s' "$WIZARDRY_DIR" | cksum | cut -d' ' -f1)
  cache_file="$cache_dir/.wizardry-glosses-$cache_id-$(id -u).sh"
  
  if [ ! -f "$cache_file" ]; then
    TEST_FAILURE_REASON="cache file not found after enabling parse"
    return 1
  fi
  
  # Check if jump function in cache routes through parse
  if grep -A100 "^jump()" "$cache_file" 2>/dev/null | grep -q "parse"; then
    # Good - it routes through parse
    return 0
  else
    TEST_FAILURE_REASON="jump function in cache doesn't route through parse"
    return 1
  fi
}

run_test_case "toggle-parse shows usage" test_help
run_test_case "toggle-parse enables parse" test_toggle_enables_parse
run_test_case "toggle-parse disables parse" test_toggle_disables_parse
run_test_case "toggle-parse twice returns to original" test_toggle_twice_returns_to_original
run_test_case "first-word glosses unloaded when disabled" test_functions_unloaded_when_disabled
run_test_case "first-word glosses loaded when enabled" test_functions_loaded_when_enabled

finish_tests
