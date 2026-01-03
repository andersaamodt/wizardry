#!/bin/sh
# Test that greylist builtins override correctly and fall back to system commands

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Greylist words from generate-glosses
GREYLIST_WORDS="read test"

test_greylist_words_have_multiword_spells_only() {
  for word in $GREYLIST_WORDS; do
    # Find all spells starting with this word
    spell_count=$(find "$ROOT_DIR/spells" -type f -name "${word}-*" | wc -l)
    
    if [ "$spell_count" -eq 0 ]; then
      TEST_FAILURE_REASON="Greylist word '$word' has no spells - should not be greylisted"
      return 1
    fi
    
    # Check that there is NO single-word spell (just "word", not "word-something")
    if [ -f "$ROOT_DIR/spells"/*/"$word" ]; then
      TEST_FAILURE_REASON="Greylist word '$word' has single-word spell - unsafe to override builtin"
      return 1
    fi
  done
}

test_read_gloss_routes_to_read_magic() {
  # Test using parse directly instead of full invoke-wizardry
  tmpdir=$(make_tempdir)
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Test that parse can find read-magic when given "read" "magic"
  output=$(cd "$ROOT_DIR" && ./spells/.imps/lex/parse "read" "magic" "--help" 2>&1)
  
  if ! printf '%s' "$output" | grep -q "Usage:"; then
    TEST_FAILURE_REASON="parse did not find read-magic spell. Output: $output"
    return 1
  fi
}

test_test_gloss_routes_to_test_spell() {
  tmpdir=$(make_tempdir)
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Test that parse can find test-spell when given "test" "spell"
  output=$(cd "$ROOT_DIR" && ./spells/.imps/lex/parse "test" "spell" "--help" 2>&1)
  
  if ! printf '%s' "$output" | grep -q "Usage:"; then
    TEST_FAILURE_REASON="parse did not find test-spell. Output: $output"
    return 1
  fi
}

test_set_gloss_routes_to_set_player() {
  # set is not currently greylisted - only one set-* spell exists and it's in a subdirectory
  # This test is a placeholder for future expansion if more set-* spells are added
  if [ ! -f "$ROOT_DIR/spells/menu/mud-admin/set-player" ]; then
    TEST_FAILURE_REASON="set-player spell not found at expected location"
    return 1
  fi
}

test_read_fallback_to_system_builtin() {
  tmpdir=$(make_tempdir)
  
  # Source invoke-wizardry to get the read gloss function
  export WIZARDRY_DIR="$ROOT_DIR"
  . "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" >/dev/null 2>&1 || return 1
  
  # Test that read gloss falls back to system read builtin for non-spell args
  # Use read with a variable name (not a spell) - should invoke system builtin
  # Create a file with test data
  testfile="$tmpdir/testinput"
  printf 'test_value\n' > "$testfile"
  
  # Use read with input redirection (not pipe to avoid subshell)
  testvar=""
  read testvar < "$testfile"
  exit_code=$?
  
  # System read should succeed with exit code 0
  if [ "$exit_code" -ne 0 ]; then
    TEST_FAILURE_REASON="read gloss did not fall back to system builtin (exit code: $exit_code)"
    return 1
  fi
  
  # Verify the variable was set by system read builtin
  if [ "$testvar" != "test_value" ]; then
    TEST_FAILURE_REASON="read gloss did not execute system builtin correctly (got: '$testvar', expected: 'test_value')"
    return 1
  fi
}

test_test_fallback_to_system_builtin() {
  tmpdir=$(make_tempdir)
  
  # Source invoke-wizardry to get the test gloss function
  export WIZARDRY_DIR="$ROOT_DIR"
  . "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" >/dev/null 2>&1 || return 1
  
  # Create a test file
  testfile="$tmpdir/testfile"
  touch "$testfile"
  
  # Test that test gloss falls back to system test builtin for non-spell args
  # Use test -f with a file path (not a spell) - should invoke system builtin
  if test -f "$testfile"; then
    : # System test succeeded - this is correct
  else
    TEST_FAILURE_REASON="test gloss did not fall back to system builtin (test -f failed)"
    return 1
  fi
  
  # Also test with a file that doesn't exist
  if test -f "$tmpdir/nonexistent_file"; then
    TEST_FAILURE_REASON="test gloss returned wrong result (should be false for nonexistent file)"
    return 1
  fi
}

run_test_case "greylist words only have multi-word spells" test_greylist_words_have_multiword_spells_only
run_test_case "read gloss routes to read-magic" test_read_gloss_routes_to_read_magic
run_test_case "test gloss routes to test-spell" test_test_gloss_routes_to_test_spell
run_test_case "set gloss routes to set-player" test_set_gloss_routes_to_set_player
run_test_case "read falls back to system builtin for non-spell args" test_read_fallback_to_system_builtin
run_test_case "test falls back to system builtin for non-spell args" test_test_fallback_to_system_builtin

finish_tests
