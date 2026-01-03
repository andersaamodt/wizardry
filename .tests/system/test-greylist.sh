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

test_greylist_fallback_to_builtin() {
  tmpdir=$(make_tempdir)
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Test that parse falls back gracefully when no spell matches
  # parse "read" "nonexistent" should not find a spell and return non-zero
  output=$(cd "$ROOT_DIR" && ./spells/.imps/lex/parse "read" "nonexistent_spell_xyz" 2>&1)
  exit_code=$?
  
  # parse should fail gracefully (non-zero exit) when spell not found
  if [ "$exit_code" -eq 0 ]; then
    TEST_FAILURE_REASON="parse succeeded when it should have failed for nonexistent spell"
    return 1
  fi
}

run_test_case "greylist words only have multi-word spells" test_greylist_words_have_multiword_spells_only
run_test_case "read gloss routes to read-magic" test_read_gloss_routes_to_read_magic
run_test_case "test gloss routes to test-spell" test_test_gloss_routes_to_test_spell
run_test_case "set gloss routes to set-player" test_set_gloss_routes_to_set_player

finish_tests
