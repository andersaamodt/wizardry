#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that all sourced-only spells use the standardized uncastable pattern

test_uncastable_pattern_is_standardized() {
  # List of spells that must be sourced (not executed)
  _sourced_spells="
    spells/arcane/jump-trash
    spells/translocation/jump-to-marker
    spells/cantrips/colors
    spells/.arcana/mud/cd
    spells/.imps/sys/env-clear
    spells/.imps/sys/invoke-thesaurus
    spells/.imps/sys/invoke-wizardry
  "
  
  for _spell in $_sourced_spells; do
    _spell_path="$ROOT_DIR/$_spell"
    
    # Check that the spell exists
    if [ ! -f "$_spell_path" ]; then
      fail "Sourced-only spell not found: $_spell"
      return 1
    fi
    
    # Check that the spell has the "# Uncastable pattern" comment
    if ! grep -q "^# Uncastable pattern" "$_spell_path"; then
      fail "Spell missing '# Uncastable pattern' comment: $_spell"
      return 1
    fi
    
    # Extract the uncastable pattern block (from comment to unset line)
    _pattern=$(sed -n '/^# Uncastable pattern/,/^unset.*_sourced.*_base/p' "$_spell_path")
    
    if [ -z "$_pattern" ]; then
      fail "Could not extract uncastable pattern from: $_spell"
      return 1
    fi
    
    # Verify the pattern contains the expected components
    if ! printf '%s\n' "$_pattern" | grep -q "_sourced=0"; then
      fail "Pattern missing '_sourced=0' initialization in: $_spell"
      return 1
    fi
    
    if ! printf '%s\n' "$_pattern" | grep -q 'ZSH_VERSION'; then
      fail "Pattern missing ZSH_VERSION check in: $_spell"
      return 1
    fi
    
    if ! printf '%s\n' "$_pattern" | grep -q 'ZSH_EVAL_CONTEXT'; then
      fail "Pattern missing ZSH_EVAL_CONTEXT check in: $_spell"
      return 1
    fi
    
    if ! printf '%s\n' "$_pattern" | grep -q 'sh|dash|bash|zsh|ksh|mksh'; then
      fail "Pattern missing shell detection in: $_spell"
      return 1
    fi
    
    if ! printf '%s\n' "$_pattern" | grep -q 'This spell cannot be cast directly'; then
      fail "Pattern missing error message in: $_spell"
      return 1
    fi
    
    if ! printf '%s\n' "$_pattern" | grep -q 'return 1 2>/dev/null || exit 1'; then
      fail "Pattern missing safe return/exit in: $_spell"
      return 1
    fi
    
    if ! printf '%s\n' "$_pattern" | grep -q 'unset.*_sourced.*_base'; then
      fail "Pattern missing cleanup (unset) in: $_spell"
      return 1
    fi
  done
  
  # Test passed - all spells have correct pattern
  return 0
}

test_uncastable_and_autocast_deleted() {
  # Verify that uncastable and autocast imps were deleted
  if [ -f "$ROOT_DIR/spells/.imps/sys/uncastable" ]; then
    fail "uncastable imp still exists - should be deleted"
    return 1
  fi
  
  if [ -f "$ROOT_DIR/spells/.imps/sys/autocast" ]; then
    fail "autocast imp still exists - should be deleted"
    return 1
  fi
  
  # Success - files don't exist
  return 0
}

run_test_case "all sourced-only spells use standardized uncastable pattern" test_uncastable_pattern_is_standardized
run_test_case "uncastable and autocast imps are deleted" test_uncastable_and_autocast_deleted
finish_tests
