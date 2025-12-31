#!/bin/sh
# Test parse gloss recursion fix

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_parse_finds_spell_file() {
  # Parse should find a spell file in WIZARDRY_DIR
  # We'll use an existing spell to test this
  run_spell "spells/.imps/lex/parse" "verify-posix" --help
  assert_success || return 1
  # verify-posix outputs to stderr (>&2)
  assert_error_contains "Usage:" || return 1
}

test_parse_self_reference_handling() {
  # Parse should handle being called for itself (self-reference)
  run_spell "spells/.imps/lex/parse" "parse" --help
  assert_success || return 1
  # parse outputs to stderr
  assert_error_contains "parse - Command execution engine" || return 1
}

test_parse_recursion_depth_limit() {
  # Create a gloss that would cause infinite recursion
  tmpdir=$(make_tempdir)
  glossary_dir="$tmpdir/spellbook/.glossary"
  spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$glossary_dir"
  mkdir -p "$spell_dir"
  
  # Create a spell that just echoes
  cat > "$spell_dir/recursive-test" <<'EOF'
#!/bin/sh
printf 'This should not run\n'
EOF
  chmod +x "$spell_dir/recursive-test"
  
  # Create a gloss that references itself
  cat > "$glossary_dir/recursive-test" <<EOF
#!/bin/sh
exec "$ROOT_DIR/spells/.imps/lex/parse" "recursive-test" "\$@"
EOF
  chmod +x "$glossary_dir/recursive-test"
  
  # Set environment to use our temp directories
  export SPELLBOOK_DIR="$tmpdir/spellbook"
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Add glossary to PATH BEFORE parse (so gloss is found first)
  old_path="$PATH"
  PATH="$glossary_dir:$PATH"
  
  # Execute the gloss directly - this should trigger recursion and eventually fail
  # We're calling the gloss, not parse directly
  output=$("$glossary_dir/recursive-test" 2>&1) || true
  PATH="$old_path"
  
  # Should either hit recursion depth limit OR eventually find the spell file
  # Either way is acceptable for this test
  case "$output" in
    *"Maximum recursion depth"*|*"This should not run"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="Expected recursion depth limit or successful execution, got: $output"
      return 1
      ;;
  esac
}

test_parse_command_not_found() {
  # Parse should return 127 for nonexistent commands
  run_spell "spells/.imps/lex/parse" "definitely-not-a-real-command-xyz"
  assert_status 127 || return 1
  assert_error_contains "command not found" || return 1
}

# Run all tests
run_test_case "parse finds spell file in WIZARDRY_DIR" test_parse_finds_spell_file
run_test_case "parse handles self-reference" test_parse_self_reference_handling
run_test_case "parse recursion handling" test_parse_recursion_depth_limit
run_test_case "parse returns 127 for missing commands" test_parse_command_not_found
finish_tests

