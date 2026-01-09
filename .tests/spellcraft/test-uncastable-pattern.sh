#!/bin/sh
# Test that all source-only spells use the standardized uncastable pattern

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_uncastable_pattern_in_jump_trash() {
  spell_file="$ROOT_DIR/spells/arcane/jump-trash"
  
  # Check for marker comment
  if ! grep -q "^# Uncastable: Must be sourced, not executed" "$spell_file"; then
    printf '%s\n' "jump-trash missing uncastable pattern marker comment" >&2
    return 1
  fi
  
  # Check pattern structure
  if ! grep -q "^_jt_sourced=0" "$spell_file"; then
    printf '%s\n' "jump-trash missing uncastable pattern variable initialization" >&2
    return 1
  fi
  
  # Check spell name in case statement
  if ! grep -q "jump-trash) _jt_sourced=0 ;;" "$spell_file"; then
    printf '%s\n' "jump-trash uncastable pattern missing spell name in case statement" >&2
    return 1
  fi
  
  # Check cleanup
  if ! grep -q "^unset _jt_sourced _jt_base" "$spell_file"; then
    printf '%s\n' "jump-trash missing uncastable pattern variable cleanup" >&2
    return 1
  fi
  
  return 0
}

test_uncastable_pattern_in_jump_to_marker() {
  spell_file="$ROOT_DIR/spells/translocation/jump-to-marker"
  
  # Check for marker comment
  if ! grep -q "^# Uncastable: Must be sourced, not executed" "$spell_file"; then
    printf '%s\n' "jump-to-marker missing uncastable pattern marker comment" >&2
    return 1
  fi
  
  # Check pattern structure
  if ! grep -q "^_jtm_sourced=0" "$spell_file"; then
    printf '%s\n' "jump-to-marker missing uncastable pattern variable initialization" >&2
    return 1
  fi
  
  # Check spell name in case statement
  if ! grep -q "jump-to-marker) _jtm_sourced=0 ;;" "$spell_file"; then
    printf '%s\n' "jump-to-marker uncastable pattern missing spell name in case statement" >&2
    return 1
  fi
  
  return 0
}

test_uncastable_pattern_in_colors() {
  spell_file="$ROOT_DIR/spells/cantrips/colors"
  
  # Check for marker comment
  if ! grep -q "^# Uncastable: Must be sourced, not executed" "$spell_file"; then
    printf '%s\n' "colors missing uncastable pattern marker comment" >&2
    return 1
  fi
  
  # Check pattern structure
  if ! grep -q "^_colors_sourced=0" "$spell_file"; then
    printf '%s\n' "colors missing uncastable pattern variable initialization" >&2
    return 1
  fi
  
  # Check spell name in case statement
  if ! grep -q "colors) _colors_sourced=0 ;;" "$spell_file"; then
    printf '%s\n' "colors uncastable pattern missing spell name in case statement" >&2
    return 1
  fi
  
  return 0
}

test_no_uncastable_imp_calls() {
  # Make sure no spells are trying to call the deprecated uncastable imp
  result=$(find "$ROOT_DIR/spells" -type f -exec grep -l "^\. uncastable\|^if ! \. uncastable\|command -v uncastable" {} \; 2>/dev/null | grep -v "compile-spell" || true)
  
  if [ -n "$result" ]; then
    printf '%s\n' "Found spells still trying to call deprecated uncastable imp:" >&2
    printf '%s\n' "$result" >&2
    return 1
  fi
  
  return 0
}

test_uncastable_imp_removed() {
  # Verify the uncastable imp file has been removed
  if [ -f "$ROOT_DIR/spells/.imps/sys/uncastable" ]; then
    printf '%s\n' "uncastable imp file still exists but should be removed" >&2
    return 1
  fi
  
  return 0
}

test_autocast_imp_removed() {
  # Verify the autocast imp file has been removed
  if [ -f "$ROOT_DIR/spells/.imps/sys/autocast" ]; then
    printf '%s\n' "autocast imp file still exists but should be removed" >&2
    return 1
  fi
  
  return 0
}

run_test_case "jump-trash uses uncastable pattern" test_uncastable_pattern_in_jump_trash
run_test_case "jump-to-marker uses uncastable pattern" test_uncastable_pattern_in_jump_to_marker
run_test_case "colors uses uncastable pattern" test_uncastable_pattern_in_colors
run_test_case "no spells call deprecated uncastable imp" test_no_uncastable_imp_calls
run_test_case "uncastable imp file removed" test_uncastable_imp_removed
run_test_case "autocast imp file removed" test_autocast_imp_removed

finish_tests
