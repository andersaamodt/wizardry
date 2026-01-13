#!/bin/sh
# Test that parse uses 'command' builtin to bypass functions/aliases during system command fallback
# This prevents exit code 139 (segfault from infinite recursion when gloss functions shadow commands)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that parse can execute real system commands (not just wizardry spells)
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
  
  # Call parse with a real system command (echo) - should work
  # This tests that parse can fall back to system commands
  run_spell "spells/.imps/lex/parse" "echo" "real command works"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "real command works" || return 1
}

# Test that parse handles nonexistent commands gracefully
test_parse_nonexistent_command() {
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/dummy" <<'EOF'
#!/bin/sh
printf 'dummy\n'
EOF
  chmod +x "$test_spell_dir/dummy"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Call parse with a nonexistent command
  run_spell "spells/.imps/lex/parse" "nonexistent-command-12345" "arg1"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  # Should fail (command not found)
  assert_failure || return 1
}

# Run all tests
run_test_case "parse executes real system commands during fallback" test_parse_real_command_fallback
run_test_case "parse handles nonexistent commands gracefully" test_parse_nonexistent_command

finish_tests
