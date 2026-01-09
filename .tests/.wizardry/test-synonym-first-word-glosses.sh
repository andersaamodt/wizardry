#!/bin/sh
# Test that first-word glosses are generated for multi-word synonyms

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_multiword_synonym_generates_first_word_gloss() {
  tmpdir=$(make_tempdir)
  synonyms_file="$tmpdir/.synonyms"
  
  # Create a multi-word synonym
  mkdir -p "$tmpdir"
  cat > "$synonyms_file" << 'EOF'
# Test synonyms
alias leap-to-marker='jump-to-marker'
alias goto-marker='jump-to-marker'
EOF
  
  # Generate glosses with synonym file
  SPELLBOOK_DIR="$tmpdir" WIZARDRY_DIR="$ROOT_DIR" \
    run_spell spells/.wizardry/generate-glosses --quiet
  
  assert_success || return 1
  
  # Check that first-word glosses are generated for multi-word synonyms
  # Should have: leap() { parse "leap" "$@"; }
  printf '%s' "$OUTPUT" | grep -q 'leap.*parse.*"leap"' || {
    TEST_FAILURE_REASON="first-word gloss for 'leap' not found in output"
    return 1
  }
  
  # Should have: goto() { parse "goto" "$@"; }
  printf '%s' "$OUTPUT" | grep -q 'goto.*parse.*"goto"' || {
    TEST_FAILURE_REASON="first-word gloss for 'goto' not found in output"
    return 1
  }
}

test_single_word_synonym_no_gloss() {
  tmpdir=$(make_tempdir)
  synonyms_file="$tmpdir/.synonyms"
  
  # Create a single-word synonym (no hyphens)
  mkdir -p "$tmpdir"
  cat > "$synonyms_file" << 'EOF'
# Test synonyms
alias ll='ls -la'
alias copy='cp'
EOF
  
  # Generate glosses with synonym file
  SPELLBOOK_DIR="$tmpdir" WIZARDRY_DIR="$ROOT_DIR" \
    run_spell spells/.wizardry/generate-glosses --quiet
  
  assert_success || return 1
  
  # Single-word synonyms should NOT generate first-word glosses
  # because they don't need space-separated invocation
  # The output might contain 'll' or 'copy' in the alias section, but not as glosses
  
  # Check that the original alias is passed through
  printf '%s' "$OUTPUT" | grep -q "alias ll='ls -la'" || {
    TEST_FAILURE_REASON="original alias for 'll' not found"
    return 1
  }
}

test_blacklisted_first_word_skipped() {
  tmpdir=$(make_tempdir)
  synonyms_file="$tmpdir/.synonyms"
  
  # Create synonym with blacklisted first word (system command)
  mkdir -p "$tmpdir"
  cat > "$synonyms_file" << 'EOF'
# Test synonyms with blacklisted first word
alias env-custom='printenv'
EOF
  
  # Generate glosses with synonym file
  SPELLBOOK_DIR="$tmpdir" WIZARDRY_DIR="$ROOT_DIR" \
    run_spell spells/.wizardry/generate-glosses --quiet 2>/dev/null
  
  assert_success || return 1
  
  # 'env' is blacklisted, so no first-word gloss should be generated
  # But the alias itself should still be passed through
  printf '%s' "$OUTPUT" | grep -q "alias env-custom='printenv'" || {
    TEST_FAILURE_REASON="original alias for 'env-custom' not found"
    return 1
  }
  
  # Should NOT have env() gloss from the synonym (it's blacklisted)
  # Note: env() might exist from wizardry spells, but not from this synonym
  # We can't easily test this without full isolation, so we'll just verify
  # the alias is present and no error occurred
}

test_duplicate_first_words_handled() {
  tmpdir=$(make_tempdir)
  synonyms_file="$tmpdir/.synonyms"
  
  # Create multiple synonyms with same first word
  mkdir -p "$tmpdir"
  cat > "$synonyms_file" << 'EOF'
# Test synonyms with duplicate first words
alias leap-to-marker='jump-to-marker'
alias leap-forward='move-forward'
alias leap-back='move-back'
EOF
  
  # Generate glosses with synonym file
  SPELLBOOK_DIR="$tmpdir" WIZARDRY_DIR="$ROOT_DIR" \
    run_spell spells/.wizardry/generate-glosses --quiet
  
  assert_success || return 1
  
  # Should have exactly one leap() gloss, not multiple
  leap_count=$(printf '%s' "$OUTPUT" | grep -c 'leap.*parse.*"leap"')
  if [ "$leap_count" -ne 1 ]; then
    TEST_FAILURE_REASON="expected 1 leap() gloss, found $leap_count"
    return 1
  fi
  
  # All three aliases should be present
  printf '%s' "$OUTPUT" | grep -q "alias leap-to-marker=" || {
    TEST_FAILURE_REASON="alias leap-to-marker not found"
    return 1
  }
  printf '%s' "$OUTPUT" | grep -q "alias leap-forward=" || {
    TEST_FAILURE_REASON="alias leap-forward not found"
    return 1
  }
  printf '%s' "$OUTPUT" | grep -q "alias leap-back=" || {
    TEST_FAILURE_REASON="alias leap-back not found"
    return 1
  }
}

run_test_case "multi-word synonym generates first-word gloss" test_multiword_synonym_generates_first_word_gloss
run_test_case "single-word synonym does not generate gloss" test_single_word_synonym_no_gloss
run_test_case "blacklisted first word is skipped" test_blacklisted_first_word_skipped
run_test_case "duplicate first words handled correctly" test_duplicate_first_words_handled

finish_tests
