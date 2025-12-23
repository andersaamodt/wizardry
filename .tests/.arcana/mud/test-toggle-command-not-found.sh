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
  
  # Initially disabled (no config file)
  env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/mud/check-command-not-found-hook" 2>/dev/null
  if [ $? -eq 0 ]; then
    TEST_FAILURE_REASON="check should fail when not configured"
    return 1
  fi
  
  # Enable it
  output=$(env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found" 2>&1)
  case "$output" in
    *enabled*)
      ;;
    *)
      TEST_FAILURE_REASON="Output missing 'enabled': $output"
      return 1
      ;;
  esac
  
  # Check it's enabled
  env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/mud/check-command-not-found-hook" 2>/dev/null
  if [ $? -ne 0 ]; then
    TEST_FAILURE_REASON="check should succeed when enabled"
    return 1
  fi
  
  # Verify config file contents
  if [ ! -f "$config_file" ]; then
    TEST_FAILURE_REASON="config file should exist"
    return 1
  fi
  
  if ! grep -q "^command-not-found=1$" "$config_file"; then
    TEST_FAILURE_REASON="config file should contain command-not-found=1"
    return 1
  fi
  
  # Disable it
  output=$(env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found" 2>&1)
  case "$output" in
    *disabled*)
      ;;
    *)
      TEST_FAILURE_REASON="Output missing 'disabled': $output"
      return 1
      ;;
  esac
  
  # Check it's disabled
  env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/mud/check-command-not-found-hook" 2>/dev/null
  if [ $? -eq 0 ]; then
    TEST_FAILURE_REASON="check should fail when disabled"
    return 1
  fi
}

test_toggle_is_idempotent() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  
  # Enable once
  output1=$(env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found" 2>&1)
  case "$output1" in
    *enabled*)
      ;;
    *)
      TEST_FAILURE_REASON="First toggle should enable: $output1"
      return 1
      ;;
  esac
  
  # Toggle again (should disable)
  output2=$(env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/.arcana/mud/toggle-command-not-found" 2>&1)
  case "$output2" in
    *disabled*)
      ;;
    *)
      TEST_FAILURE_REASON="Second toggle should disable: $output2"
      return 1
      ;;
  esac
}

test_invoke_wizardry_respects_toggle() {
  skip-if-compiled || return $?
  tmpdir=$(_make_tempdir)
  config_file="$tmpdir/.spellbook/.mud/config"
  mkdir -p "$(dirname "$config_file")"
  
  # Test 1: With command-not-found disabled
  printf 'command-not-found=0\n' > "$config_file"
  
  env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/mud/check-command-not-found-hook" 2>/dev/null
  if [ $? -eq 0 ]; then
    TEST_FAILURE_REASON="should be disabled"
    return 1
  fi
  
  # Test 2: With command-not-found enabled
  printf 'command-not-found=1\n' > "$config_file"
  
  env SPELLBOOK_DIR="$tmpdir/.spellbook" sh "$ROOT_DIR/spells/mud/check-command-not-found-hook" 2>/dev/null
  if [ $? -ne 0 ]; then
    TEST_FAILURE_REASON="should be enabled"
    return 1
  fi
}

_run_test_case "toggle enables and disables" test_toggle_enables_and_disables
_run_test_case "toggle is idempotent" test_toggle_is_idempotent
_run_test_case "invoke-wizardry respects toggle" test_invoke_wizardry_respects_toggle

_finish_tests
