#!/bin/sh
# Test that all spells use underscore function names internally
# - Spell function names must use underscores, not hyphens
# - Spell calls to other spells must use underscores, not hyphens
# - Usage text and comments may use hyphens for user-facing names

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_no_hyphenated_function_definitions() {
  # Check that spell functions are defined with underscores, not hyphens
  # Pattern: function-name() { should be function_name() {
  
  found_violations=0
  violations=""
  
  # Search all spell files (excluding .imps and .arcana)
  find "$ROOT_DIR/spells" -type f -executable \
    ! -path "*/.imps/*" \
    ! -path "*/.arcana/*" \
    ! -name ".*" | while read -r spell_file; do
    
    # Look for function definitions with hyphens
    # Match: spell-name() or spell-name () at start of line
    if grep -nE "^[a-z][a-z0-9]*-[a-z0-9-]*\s*\(\)" "$spell_file" | grep -v "^\s*#"; then
      violations="${violations}${spell_file}\n"
      found_violations=$((found_violations + 1))
    fi
  done
  
  if [ "$found_violations" -gt 0 ]; then
    printf 'Found spell functions with hyphenated names (should use underscores):\n' >&2
    printf '%s' "$violations" >&2
    return 1
  fi
  
  return 0
}

test_no_hyphenated_spell_calls() {
  # Check that spells call other spells with underscores, not hyphens
  # Common spell calls: ask-yn, ask-text, ask-number, read-magic, file-list, validate-spells
  
  found_violations=0
  violations=""
  
  # List of spell names that should be called with underscores
  hyphenated_spells="ask-yn ask-text ask-number read-magic file-list validate-spells"
  
  # Search all spell files (excluding .imps and .arcana)
  find "$ROOT_DIR/spells" -type f -executable \
    ! -path "*/.imps/*" \
    ! -path "*/.arcana/*" \
    ! -name ".*" | while read -r spell_file; do
    
    # Check for hyphenated spell calls (not in comments or usage strings)
    for spell in $hyphenated_spells; do
      # Look for: spell-name followed by space (function call)
      # But skip lines with Usage:, Examples:, or starting with #
      if grep -nE "\b${spell}\s+" "$spell_file" | \
         grep -v "^\s*#" | \
         grep -v "Usage:" | \
         grep -v "Examples:" | \
         grep -v "cat <<" > /dev/null 2>&1; then
        
        violation_lines=$(grep -nE "\b${spell}\s+" "$spell_file" | \
          grep -v "^\s*#" | \
          grep -v "Usage:" | \
          grep -v "Examples:" | \
          grep -v "cat <<")
        
        if [ -n "$violation_lines" ]; then
          printf 'Found hyphenated spell call "%s" in %s:\n' "$spell" "$spell_file" >&2
          printf '%s\n' "$violation_lines" >&2
          found_violations=$((found_violations + 1))
        fi
      fi
    done
  done
  
  if [ "$found_violations" -gt 0 ]; then
    printf '\nSpells should call other spells with underscores, not hyphens.\n' >&2
    printf 'Examples: ask_yn, ask_text, read_magic, validate_spells\n' >&2
    printf 'Usage text and comments may use hyphens for user-facing names.\n' >&2
    return 1
  fi
  
  return 0
}

test_spell_functions_use_underscores() {
  # Positive test: Verify that common spells DO use underscore names
  
  # Check ask-yn spell has ask_yn function
  if ! grep -q "^ask_yn()" "$ROOT_DIR/spells/cantrips/ask-yn"; then
    printf 'ask-yn spell should define ask_yn() function\n' >&2
    return 1
  fi
  
  # Check read-magic spell has read_magic function
  if ! grep -q "^read_magic()" "$ROOT_DIR/spells/arcane/read-magic"; then
    printf 'read-magic spell should define read_magic() function\n' >&2
    return 1
  fi
  
  # Check validate-spells spell has validate_spells function
  if ! grep -q "^validate_spells()" "$ROOT_DIR/spells/system/validate-spells"; then
    printf 'validate-spells spell should define validate_spells() function\n' >&2
    return 1
  fi
  
  return 0
}

test_usage_text_preserves_hyphens() {
  # Verify that usage text still uses hyphenated names for users
  
  # Check ask-yn usage shows "ask-yn" not "ask_yn"
  if ! grep -q "Usage: ask-yn" "$ROOT_DIR/spells/cantrips/ask-yn"; then
    printf 'ask-yn usage should show hyphenated name for users\n' >&2
    return 1
  fi
  
  # Check read-magic usage shows "read-magic" not "read_magic"
  if ! grep -q "Usage: read-magic" "$ROOT_DIR/spells/arcane/read-magic"; then
    printf 'read-magic usage should show hyphenated name for users\n' >&2
    return 1
  fi
  
  return 0
}

run_test_case "no hyphenated function definitions" test_no_hyphenated_function_definitions
run_test_case "no hyphenated spell calls in code" test_no_hyphenated_spell_calls
run_test_case "spell functions use underscores" test_spell_functions_use_underscores
run_test_case "usage text preserves hyphens for users" test_usage_text_preserves_hyphens

finish_tests
