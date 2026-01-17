#!/bin/sh
# Tests for parse avoiding infinite recursion with gloss functions
# This test verifies the fix for the bug where parse would exec gloss functions,
# causing infinite recursion and segfaults

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that parse doesn't try to exec functions (which would cause infinite recursion)
test_parse_skips_functions() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  # Create a spell that should be found
  cat > "$test_spell_dir/testspell" <<'EOF'
#!/bin/sh
printf 'testspell executed\n'
EOF
  chmod +x "$test_spell_dir/testspell"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Define a function with the same name
  testspell() {
    printf 'ERROR: function was called instead of spell!\n'
    return 1
  }
  
  # Call parse - it should find the spell file, not try to exec the function
  run_spell "spells/.imps/lex/parse" "testspell"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "testspell executed" || return 1
  # Verify function was NOT called
  if printf '%s' "$OUTPUT" | grep -q "function was called"; then
    TEST_FAILURE_REASON="Function was called instead of spell"
    return 1
  fi
}

# Test that parse doesn't exec a function when no spell exists (last-resort path)
test_parse_skips_function_fallback() {
  _saved_wizdir="${WIZARDRY_DIR-}"

  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/wizardry/spells"
  export WIZARDRY_DIR="$tmpdir/wizardry"

  fallback() {
    printf 'ERROR: fallback function executed\n'
    return 1
  }

  run_spell "spells/.imps/lex/parse" "fallback"

  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi

  assert_status 127 || return 1
  case "$OUTPUT" in
    *"fallback function executed"*)
      TEST_FAILURE_REASON="Function was executed via fallback path"
      return 1
      ;;
  esac
  assert_error_contains "command not found" || return 1
}

# Test that parse doesn't exec builtins either
test_parse_skips_builtins() {
  # Save original WIZARDRY_DIR  
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  # Create a spell with a builtin name
  cat > "$test_spell_dir/echo" <<'EOF'
#!/bin/sh
printf 'custom echo spell\n'
EOF
  chmod +x "$test_spell_dir/echo"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Call parse with "echo" - should find our custom spell, not try to exec the builtin
  run_spell "spells/.imps/lex/parse" "echo"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "custom echo spell" || return 1
}

# Run all tests
run_test_case "parse skips functions to avoid recursion" test_parse_skips_functions
run_test_case "parse skips function fallback" test_parse_skips_function_fallback
run_test_case "parse skips builtins" test_parse_skips_builtins

finish_tests
