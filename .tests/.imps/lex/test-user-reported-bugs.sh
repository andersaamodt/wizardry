#!/bin/sh
# Comprehensive test reproducing EXACT bugs from user logs
# This must catch ALL the failures the user reported

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Test 1: User typed "jump-to-marker" - should work
test_user_typed_jump_to_marker_hyphenated() {
  OUTPUT=$(jump-to-marker 2>&1)
  STATUS=$?
  
  # Must NOT contain shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="FAIL: Got shift error: $OUTPUT"
    return 1
  fi
  
  # Must NOT contain parse error with multiple args
  if printf '%s' "$OUTPUT" | grep -q "parse:.*jump-to.*jump-to-marker.*jump:"; then
    TEST_FAILURE_REASON="FAIL: Parse called with multiple candidates: $OUTPUT"
    return 1
  fi
  
  # Should get valid output (either usage or "no markers" message)
  if ! printf '%s' "$OUTPUT" | grep -qE "(Usage:|No markers|cannot be cast)"; then
    TEST_FAILURE_REASON="FAIL: Unexpected output: $OUTPUT"
    return 1
  fi
}

# Test 2: User typed "jump to marker" - should work
test_user_typed_jump_to_marker_spaces() {
  OUTPUT=$(jump to marker 2>&1)
  STATUS=$?
  
  # Must NOT contain shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="FAIL: Got shift error: $OUTPUT"
    return 1
  fi
  
  # Must NOT contain parse error
  if printf '%s' "$OUTPUT" | grep -q "parse:.*jump-to.*jump-to-marker.*jump:"; then
    TEST_FAILURE_REASON="FAIL: Parse called with multiple candidates: $OUTPUT"
    return 1
  fi
  
  # Should get valid output
  if ! printf '%s' "$OUTPUT" | grep -qE "(Usage:|No markers)"; then
    TEST_FAILURE_REASON="FAIL: Unexpected output: $OUTPUT"
    return 1
  fi
}

# Test 3: User typed "jump" - should work (this one worked in logs)
test_user_typed_jump_alone() {
  # jump without args should work (cycles through markers or shows message)
  OUTPUT=$(printf '' | jump 2>&1)
  STATUS=$?
  
  # Should not have shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="FAIL: Got shift error: $OUTPUT"
    return 1
  fi
  
  # Should not have parse error  
  if printf '%s' "$OUTPUT" | grep -q "parse:.*command not found"; then
    TEST_FAILURE_REASON="FAIL: Parse error: $OUTPUT"
    return 1
  fi
}

# Test 4: User typed "jump to location" with custom synonym
test_user_typed_jump_to_location() {
  # Set up custom synonym
  tmpspellbook=$(make_tempdir)
  mkdir -p "$tmpspellbook"
  printf 'jump-to-location=jump-to-marker\n' > "$tmpspellbook/.synonyms"
  
  saved_spellbook="${SPELLBOOK_DIR-}"
  export SPELLBOOK_DIR="$tmpspellbook"
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Regenerate glosses with synonym
  tmpgloss="$tmpspellbook/glosses"
  "$ROOT_DIR/spells/.wizardry/generate-glosses" --output "$tmpgloss" --quiet
  . "$tmpgloss"
  
  OUTPUT=$(jump to location 2>&1)
  
  # Restore
  if [ -n "$saved_spellbook" ]; then export SPELLBOOK_DIR="$saved_spellbook"; else unset SPELLBOOK_DIR; fi
  
  # Must NOT contain shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="FAIL: Got shift error: $OUTPUT"
    return 1
  fi
  
  # Must NOT contain parse error
  if printf '%s' "$OUTPUT" | grep -q "parse:.*jump-to.*jump-to-location.*jump:"; then
    TEST_FAILURE_REASON="FAIL: Parse called with multiple candidates: $OUTPUT"
    return 1
  fi
  
  # Should get valid output
  if ! printf '%s' "$OUTPUT" | grep -qE "(Usage:|No markers|cannot be cast)"; then
    TEST_FAILURE_REASON="FAIL: Unexpected output: $OUTPUT"
    return 1
  fi
}

# Test 5: User typed "jump-to-location" (hyphenated) with custom synonym
test_user_typed_jump_to_location_hyphenated() {
  # Set up custom synonym
  tmpspellbook=$(make_tempdir)
  mkdir -p "$tmpspellbook"
  printf 'jump-to-location=jump-to-marker\n' > "$tmpspellbook/.synonyms"
  
  saved_spellbook="${SPELLBOOK_DIR-}"
  export SPELLBOOK_DIR="$tmpspellbook"
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Regenerate glosses with synonym
  tmpgloss="$tmpspellbook/glosses"
  "$ROOT_DIR/spells/.wizardry/generate-glosses" --output "$tmpgloss" --quiet
  . "$tmpgloss"
  
  OUTPUT=$(jump-to-location 2>&1)
  
  # Restore
  if [ -n "$saved_spellbook" ]; then export SPELLBOOK_DIR="$saved_spellbook"; else unset SPELLBOOK_DIR; fi
  
  # Must NOT contain shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="FAIL: Got shift error: $OUTPUT"
    return 1
  fi
  
  # Must NOT contain parse error
  if printf '%s' "$OUTPUT" | grep -q "parse:.*jump-to.*jump-to-location.*jump:"; then
    TEST_FAILURE_REASON="FAIL: Parse called with multiple candidates: $OUTPUT"
    return 1
  fi
  
  # Should get valid output
  if ! printf '%s' "$OUTPUT" | grep -qE "(Usage:|No markers|cannot be cast)"; then
    TEST_FAILURE_REASON="FAIL: Unexpected output: $OUTPUT"
    return 1
  fi
}

# Test 6: User typed "leap-to-location" with custom synonym
test_user_typed_leap_to_location_hyphenated() {
  tmpspellbook=$(make_tempdir)
  mkdir -p "$tmpspellbook"
  printf 'leap-to-location=jump-to-marker\n' > "$tmpspellbook/.synonyms"
  
  saved_spellbook="${SPELLBOOK_DIR-}"
  export SPELLBOOK_DIR="$tmpspellbook"
  export WIZARDRY_DIR="$ROOT_DIR"
  
  tmpgloss="$tmpspellbook/glosses"
  "$ROOT_DIR/spells/.wizardry/generate-glosses" --output "$tmpgloss" --quiet
  . "$tmpgloss"
  
  OUTPUT=$(leap-to-location 2>&1)
  
  if [ -n "$saved_spellbook" ]; then export SPELLBOOK_DIR="$saved_spellbook"; else unset SPELLBOOK_DIR; fi
  
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="FAIL: Got shift error: $OUTPUT"
    return 1
  fi
  
  if printf '%s' "$OUTPUT" | grep -q "parse:.*leap-to.*leap-to-location.*leap:"; then
    TEST_FAILURE_REASON="FAIL: Parse called with multiple candidates: $OUTPUT"
    return 1
  fi
  
  if ! printf '%s' "$OUTPUT" | grep -qE "(Usage:|No markers|cannot be cast)"; then
    TEST_FAILURE_REASON="FAIL: Unexpected output: $OUTPUT"
    return 1
  fi
}

# Test 7: User typed "leap to location" with custom synonym
test_user_typed_leap_to_location_spaces() {
  tmpspellbook=$(make_tempdir)
  mkdir -p "$tmpspellbook"
  printf 'leap-to-location=jump-to-marker\n' > "$tmpspellbook/.synonyms"
  
  saved_spellbook="${SPELLBOOK_DIR-}"
  export SPELLBOOK_DIR="$tmpspellbook"
  export WIZARDRY_DIR="$ROOT_DIR"
  
  tmpgloss="$tmpspellbook/glosses"
  "$ROOT_DIR/spells/.wizardry/generate-glosses" --output "$tmpgloss" --quiet
  . "$tmpgloss"
  
  OUTPUT=$(leap to location 2>&1)
  
  if [ -n "$saved_spellbook" ]; then export SPELLBOOK_DIR="$saved_spellbook"; else unset SPELLBOOK_DIR; fi
  
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="FAIL: Got shift error: $OUTPUT"
    return 1
  fi
  
  if printf '%s' "$OUTPUT" | grep -q "parse:.*leap-to.*leap-to-location.*leap:"; then
    TEST_FAILURE_REASON="FAIL: Parse called with multiple candidates: $OUTPUT"
    return 1
  fi
  
  if ! printf '%s' "$OUTPUT" | grep -qE "(Usage:|No markers|cannot be cast)"; then
    TEST_FAILURE_REASON="FAIL: Unexpected output: $OUTPUT"
    return 1
  fi
}

# Test 8: User typed "warp" with custom synonym
test_user_typed_warp() {
  tmpspellbook=$(make_tempdir)
  mkdir -p "$tmpspellbook"
  printf 'warp=jump-to-marker\n' > "$tmpspellbook/.synonyms"
  
  saved_spellbook="${SPELLBOOK_DIR-}"
  export SPELLBOOK_DIR="$tmpspellbook"
  export WIZARDRY_DIR="$ROOT_DIR"
  
  tmpgloss="$tmpspellbook/glosses"
  "$ROOT_DIR/spells/.wizardry/generate-glosses" --output "$tmpgloss" --quiet
  . "$tmpgloss"
  
  OUTPUT=$(warp 2>&1)
  
  if [ -n "$saved_spellbook" ]; then export SPELLBOOK_DIR="$saved_spellbook"; else unset SPELLBOOK_DIR; fi
  
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="FAIL: Got shift error: $OUTPUT"
    return 1
  fi
  
  if printf '%s' "$OUTPUT" | grep -q "parse:.*jump-to.*jump-to-marker.*jump:"; then
    TEST_FAILURE_REASON="FAIL: Parse called with multiple candidates: $OUTPUT"
    return 1
  fi
  
  if ! printf '%s' "$OUTPUT" | grep -qE "(Usage:|No markers|cannot be cast)"; then
    TEST_FAILURE_REASON="FAIL: Unexpected output: $OUTPUT"
    return 1
  fi
}

run_test_case "USER LOG: jump-to-marker" test_user_typed_jump_to_marker_hyphenated
run_test_case "USER LOG: jump to marker" test_user_typed_jump_to_marker_spaces
run_test_case "USER LOG: jump (alone, worked)" test_user_typed_jump_alone
run_test_case "USER LOG: jump to location" test_user_typed_jump_to_location
run_test_case "USER LOG: jump-to-location" test_user_typed_jump_to_location_hyphenated
run_test_case "USER LOG: leap-to-location" test_user_typed_leap_to_location_hyphenated
run_test_case "USER LOG: leap to location" test_user_typed_leap_to_location_spaces
run_test_case "USER LOG: warp" test_user_typed_warp

finish_tests
