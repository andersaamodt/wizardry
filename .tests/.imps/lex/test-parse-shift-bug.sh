#!/bin/sh
# Test for the shift count bug reported in PR comments
# Bug: jump-to-marker fails with "shift count must be <= $#"

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_jump_to_marker_no_args() {
  # Test that jump-to-marker works without arguments (doesn't try to over-shift)
  OUTPUT=$(jump-to-marker 2>&1)
  STATUS=$?
  
  # Should not fail with shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Got shift count error: $OUTPUT"
    return 1
  fi
  
  # Should give expected error (no markers set) or usage message
  if ! printf '%s' "$OUTPUT" | grep -qE "(No markers|Usage:|cannot be cast directly)"; then
    TEST_FAILURE_REASON="Unexpected output: $OUTPUT"
    return 1
  fi
}

test_jump_to_marker_with_spaces_no_args() {
  # Test that "jump to marker" works without arguments
  OUTPUT=$(jump to marker 2>&1)
  STATUS=$?
  
  # Should not fail with shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Got shift count error: $OUTPUT"
    return 1
  fi
  
  # Should give expected error (no markers set)
  if ! printf '%s' "$OUTPUT" | grep -qE "(No markers|Usage:)"; then
    TEST_FAILURE_REASON="Unexpected output: $OUTPUT"
    return 1
  fi
}

test_jump_to_location_no_args() {
  # Test with custom synonym (if it exists)
  # Create temporary synonym
  tmpspellbook=$(make_tempdir)
  mkdir -p "$tmpspellbook"
  printf 'jump-to-location=jump-to-marker\n' > "$tmpspellbook/.synonyms"
  
  saved_spellbook="${SPELLBOOK_DIR-}"
  export SPELLBOOK_DIR="$tmpspellbook"
  
  # Regenerate glosses
  tmpgloss="$tmpspellbook/glosses"
  export WIZARDRY_DIR="$ROOT_DIR"
  "$ROOT_DIR/spells/.wizardry/generate-glosses" --output "$tmpgloss" --quiet
  
  # Source glosses
  . "$tmpgloss"
  
  # Test "jump to location" with no args
  OUTPUT=$(jump to location 2>&1)
  STATUS=$?
  
  # Restore
  if [ -n "$saved_spellbook" ]; then export SPELLBOOK_DIR="$saved_spellbook"; else unset SPELLBOOK_DIR; fi
  
  # Should not fail with shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Got shift count error: $OUTPUT"
    return 1
  fi
  
  # Should give expected error or usage
  if ! printf '%s' "$OUTPUT" | grep -qE "(No markers|Usage:|cannot be cast directly)"; then
    TEST_FAILURE_REASON="Unexpected output: $OUTPUT"
    return 1
  fi
}

run_test_case "jump-to-marker without args (no shift error)" test_jump_to_marker_no_args
run_test_case "jump to marker without args (no shift error)" test_jump_to_marker_with_spaces_no_args
run_test_case "jump to location without args (no shift error)" test_jump_to_location_no_args

finish_tests
