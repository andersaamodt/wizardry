#!/bin/sh
# Test that parse correctly handles fallback to system commands when gloss functions exist
# This is the exact scenario that caused exit code 139 (segfault from infinite recursion)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that parse skips functions when falling back to system commands
test_parse_function_fallback_no_recursion() {
  # Create a minimal WIZARDRY_DIR with no spell named "printf"
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  # Create a dummy spell so the directory structure is valid
  cat > "$test_spell_dir/dummy" <<'EOF'
#!/bin/sh
printf 'dummy\n'
EOF
  chmod +x "$test_spell_dir/dummy"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Define a gloss-like function that would cause infinite recursion if exec'd
  # Use printf (a real command) to test that parse skips the function and execs the real command
  printf() {
    printf 'ERROR: gloss function was called - infinite recursion!\n' >&2
    return 1
  }
  
  # Call parse with "printf" - there's no spell file for it, so it will try to
  # fall back to the system command. It should skip the function and exec the real
  # printf builtin, not call the function (which would cause infinite recursion)
  run_spell "spells/.imps/lex/parse" "printf" "success: real command executed\n"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  # Should NOT fail with exit code 139 (segfault from infinite recursion)
  if [ "${EXIT_CODE:-0}" -eq 139 ]; then
    TEST_FAILURE_REASON="Got exit code 139 (segfault) - infinite recursion not prevented"
    return 1
  fi
  
  # Should succeed (real command executed)
  assert_success || return 1
  
  # Should show output from real printf, not call the function
  assert_output_contains "success: real command executed" || return 1
  
  # Verify the gloss function was NOT called (which would show the ERROR message)
  if printf '%s' "$OUTPUT" | grep -q "gloss function was called"; then
    TEST_FAILURE_REASON="Gloss function was executed - recursion not prevented"
    return 1
  fi
}

# Test that parse DOES exec real system commands when no function exists
test_parse_real_command_fallback() {
  # Create a minimal WIZARDRY_DIR with no spell named "printf"
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  # Create a dummy spell
  cat > "$test_spell_dir/dummy" <<'EOF'
#!/bin/sh
printf 'dummy\n'
EOF
  chmod +x "$test_spell_dir/dummy"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Call parse with a real system command (printf) - should work
  run_spell "spells/.imps/lex/parse" "printf" "real command works\n"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "real command works" || return 1
}

# Run all tests
run_test_case "parse skips gloss functions during fallback (prevents exit 139)" test_parse_function_fallback_no_recursion
run_test_case "parse executes real system commands during fallback" test_parse_real_command_fallback

finish_tests
