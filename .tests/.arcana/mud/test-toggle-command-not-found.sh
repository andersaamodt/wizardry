#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_toggle_enables_and_disables() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  config_file="$tmpdir/.spellbook/.mud/config"
  
  # Initially enabled (default when no config)
  env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/mud/check-command-not-found-hook" 2>/dev/null
  if [ $? -ne 0 ]; then
    TEST_FAILURE_REASON="check should succeed when not configured (defaults to enabled)"
    return 1
  fi
  
  # Disable it
  output=$(env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found" 2>&1)
  case "$output" in
    *disabled*)
      ;;
    *)
      TEST_FAILURE_REASON="First toggle should disable: $output"
      return 1
      ;;
  esac
  
  # Check it's disabled
  env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/mud/check-command-not-found-hook" 2>/dev/null
  if [ $? -eq 0 ]; then
    TEST_FAILURE_REASON="check should fail when disabled"
    return 1
  fi
  
  # Verify config file has command-not-found=0
  if [ ! -f "$config_file" ]; then
    TEST_FAILURE_REASON="config file should exist"
    return 1
  fi
  
  if ! grep -q "^command-not-found=0$" "$config_file"; then
    TEST_FAILURE_REASON="config file should contain command-not-found=0, got: $(cat "$config_file")"
    return 1
  fi
  
  # Enable it again
  output=$(env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found" 2>&1)
  case "$output" in
    *enabled*)
      ;;
    *)
      TEST_FAILURE_REASON="Second toggle should enable: $output"
      return 1
      ;;
  esac
  
  # Check it's enabled
  env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/mud/check-command-not-found-hook" 2>/dev/null
  if [ $? -ne 0 ]; then
    TEST_FAILURE_REASON="check should succeed when enabled"
    return 1
  fi
  
  # Verify config no longer has command-not-found=0 (removed for default enabled)
  if grep -q "^command-not-found=0$" "$config_file" 2>/dev/null; then
    TEST_FAILURE_REASON="config file should not contain command-not-found=0 after re-enabling"
    return 1
  fi
}

test_toggle_is_idempotent() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  
  # Default is enabled, first toggle disables
  output1=$(env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found" 2>&1)
  case "$output1" in
    *disabled*)
      ;;
    *)
      TEST_FAILURE_REASON="First toggle should disable (from default enabled): $output1"
      return 1
      ;;
  esac
  
  # Toggle again (should enable)
  output2=$(env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found" 2>&1)
  case "$output2" in
    *enabled*)
      ;;
    *)
      TEST_FAILURE_REASON="Second toggle should enable: $output2"
      return 1
      ;;
  esac
}

test_invoke_wizardry_respects_toggle() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  config_file="$tmpdir/.spellbook/.mud/config"
  mkdir -p "$(dirname "$config_file")"
  
  # Test 1: With command-not-found explicitly disabled
  printf 'command-not-found=0\n' > "$config_file"
  
  env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/mud/check-command-not-found-hook" 2>/dev/null
  if [ $? -eq 0 ]; then
    TEST_FAILURE_REASON="should be disabled when set to 0"
    return 1
  fi
  
  # Test 2: With no config (defaults to enabled)
  rm -f "$config_file"
  
  env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/mud/check-command-not-found-hook" 2>/dev/null
  if [ $? -ne 0 ]; then
    TEST_FAILURE_REASON="should be enabled when not configured (default)"
    return 1
  fi
  
  # Test 3: With command-not-found explicitly enabled (though not necessary)
  printf 'command-not-found=1\n' > "$config_file"
  
  env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/mud/check-command-not-found-hook" 2>/dev/null
  if [ $? -ne 0 ]; then
    TEST_FAILURE_REASON="should be enabled when explicitly set to 1"
    return 1
  fi
}

_run_test_case "toggle enables and disables" test_toggle_enables_and_disables
_run_test_case "toggle is idempotent" test_toggle_is_idempotent
_run_test_case "invoke-wizardry respects toggle" test_invoke_wizardry_respects_toggle

_finish_tests
