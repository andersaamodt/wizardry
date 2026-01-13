#!/bin/sh
# Test custom synonyms with multi-word gloss commands
# This reproduces the bugs reported with warp and leap-to-location

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Note: These tests require custom synonyms to be set up
# They test that the gloss/parse system correctly handles user-defined synonyms

test_custom_synonym_single_word() {
  # This test verifies that a single-word synonym (warp) works
  # To test locally, add to ~/.spellbook/.synonyms: warp=jump-to-marker
  
  # Create temporary synonym
  tmpspellbook=$(make_tempdir)
  mkdir -p "$tmpspellbook"
  printf 'warp=jump-to-marker\n' > "$tmpspellbook/.synonyms"
  
  # Save current state
  saved_spellbook="${SPELLBOOK_DIR-}"
  saved_home="${HOME-}"
  
  # Set up environment and regenerate glosses  
  export SPELLBOOK_DIR="$tmpspellbook"
  export HOME="$tmpspellbook"
  
  # Regenerate glosses
  tmpgloss="$tmpspellbook/glosses"
  export WIZARDRY_DIR="$ROOT_DIR"
  "$ROOT_DIR/spells/.wizardry/generate-glosses" --output "$tmpgloss" --quiet
  
  # Source glosses in current shell
  . "$tmpgloss"
  
  # Test warp command
  OUTPUT=$(warp --help 2>&1)
  STATUS=$?
  
  # Restore environment
  if [ -n "$saved_spellbook" ]; then export SPELLBOOK_DIR="$saved_spellbook"; else unset SPELLBOOK_DIR; fi
  if [ -n "$saved_home" ]; then export HOME="$saved_home"; else unset HOME; fi
  
  if [ $STATUS -ne 0 ]; then
    TEST_FAILURE_REASON="warp failed with status $STATUS"
    return 1
  fi
  
  if ! printf '%s' "$OUTPUT" | grep -q "Usage:"; then
    TEST_FAILURE_REASON="warp output missing 'Usage:'"
    return 1
  fi
}

test_custom_synonym_multi_word_spaces() {
  # This test verifies that a multi-word synonym works with spaces (leap to location)
  # To test locally, add to ~/.spellbook/.synonyms: leap-to-location=jump-to-marker
  
  # Create temporary synonym
  tmpspellbook=$(make_tempdir)
  mkdir -p "$tmpspellbook"
  printf 'leap-to-location=jump-to-marker\n' > "$tmpspellbook/.synonyms"
  
  # Save current state
  saved_spellbook="${SPELLBOOK_DIR-}"
  saved_home="${HOME-}"
  
  # Set up environment and regenerate glosses
  export SPELLBOOK_DIR="$tmpspellbook"
  export HOME="$tmpspellbook"
  
  # Regenerate glosses
  tmpgloss="$tmpspellbook/glosses"
  export WIZARDRY_DIR="$ROOT_DIR"
  "$ROOT_DIR/spells/.wizardry/generate-glosses" --output "$tmpgloss" --quiet
  
  # Source glosses in current shell
  . "$tmpgloss"
  
  # Test "leap to location" command (spaces)
  OUTPUT=$(leap to location --help 2>&1)
  STATUS=$?
  
  # Restore environment
  if [ -n "$saved_spellbook" ]; then export SPELLBOOK_DIR="$saved_spellbook"; else unset SPELLBOOK_DIR; fi
  if [ -n "$saved_home" ]; then export HOME="$saved_home"; else unset HOME; fi
  
  if [ $STATUS -ne 0 ]; then
    TEST_FAILURE_REASON="leap to location failed with status $STATUS"
    return 1
  fi
  
  if ! printf '%s' "$OUTPUT" | grep -q "Usage:"; then
    TEST_FAILURE_REASON="leap to location output missing 'Usage:'"
    return 1
  fi
}

run_test_case "custom synonym single-word (warp)" test_custom_synonym_single_word
run_test_case "custom synonym multi-word with spaces (leap to location)" test_custom_synonym_multi_word_spaces

finish_tests
