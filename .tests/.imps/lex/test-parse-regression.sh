#!/bin/sh
# Regression tests for parse bugs discovered and fixed in PR #934
# These tests ensure we don't re-introduce the bugs that caused segfaults

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Bug: Parse counted command words correctly but built names with ALL args including numbers
# Test: Ensure "banish 5" calls banish with arg 5, not looks for "banish-5"
test_parse_building_skips_numeric_args() {
  _saved_wizdir="${WIZARDRY_DIR-}"
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/wards"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/banish" <<'EOF'
#!/bin/sh
printf 'banish executed with args: %s\n' "$*"
EOF
  chmod +x "$test_spell_dir/banish"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  run_spell "spells/.imps/lex/parse" "banish" "5"
  
  if [ -n "$_saved_wizdir" ]; then export WIZARDRY_DIR="$_saved_wizdir"; else unset WIZARDRY_DIR; fi
  
  assert_success || return 1
  assert_output_contains "banish executed with args: 5" || return 1
}

# Bug: Parse tried to exec gloss functions when spell not found, causing infinite recursion
# Test: Ensure parse skips functions and doesn't cause segfault
test_parse_doesnt_exec_functions() {
  _saved_wizdir="${WIZARDRY_DIR-}"
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/mycommand" <<'EOF'
#!/bin/sh
printf 'spell executed\n'
EOF
  chmod +x "$test_spell_dir/mycommand"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Define a function with the same name (like gloss functions do)
  mycommand() {
    printf 'ERROR: function was called - infinite recursion would occur!\n'
    return 1
  }
  
  run_spell "spells/.imps/lex/parse" "mycommand"
  
  if [ -n "$_saved_wizdir" ]; then export WIZARDRY_DIR="$_saved_wizdir"; else unset WIZARDRY_DIR; fi
  
  assert_success || return 1
  assert_output_contains "spell executed" || return 1
  # Verify function was NOT called (no "function was called" in output)
  if printf '%s' "$OUTPUT" | grep -q "function was called"; then
    TEST_FAILURE_REASON="Function was called instead of spell - infinite recursion would occur"
    return 1
  fi
}

# Bug: Parse used non-POSIX `type` command
# Test: Ensure parse works on POSIX shells (no `type` dependency)
test_parse_posix_compliant() {
  _saved_wizdir="${WIZARDRY_DIR-}"
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/test-posix" <<'EOF'
#!/bin/sh
printf 'POSIX compliance OK\n'
EOF
  chmod +x "$test_spell_dir/test-posix"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Unset type if it exists (to simulate POSIX-only environment)
  # Note: Can't actually unset builtins, but we can verify parse doesn't fail
  run_spell "spells/.imps/lex/parse" "test" "posix"
  
  if [ -n "$_saved_wizdir" ]; then export WIZARDRY_DIR="$_saved_wizdir"; else unset WIZARDRY_DIR; fi
  
  assert_success || return 1
  assert_output_contains "POSIX compliance OK" || return 1
}

# Bug: Parse treated flags as command name components
# Test: Ensure "--flag" doesn't become part of command name
test_parse_building_skips_flags() {
  _saved_wizdir="${WIZARDRY_DIR-}"
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/myspell" <<'EOF'
#!/bin/sh
printf 'myspell got: %s\n' "$*"
EOF
  chmod +x "$test_spell_dir/myspell"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  run_spell "spells/.imps/lex/parse" "myspell" "--verbose" "arg"
  
  if [ -n "$_saved_wizdir" ]; then export WIZARDRY_DIR="$_saved_wizdir"; else unset WIZARDRY_DIR; fi
  
  assert_success || return 1
  assert_output_contains "myspell got: --verbose arg" || return 1
}

# Bug: Multi-word commands with numeric args incorrectly built "jump-to-5" instead of "jump-to" with arg "5"
# Test: Ensure multi-word command with numeric arg works correctly
test_parse_multiword_with_number() {
  _saved_wizdir="${WIZARDRY_DIR-}"
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/arcane"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/leap-to" <<'EOF'
#!/bin/sh
printf 'leap-to called with: %s\n' "$*"
EOF
  chmod +x "$test_spell_dir/leap-to"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  run_spell "spells/.imps/lex/parse" "leap" "to" "5"
  
  if [ -n "$_saved_wizdir" ]; then export WIZARDRY_DIR="$_saved_wizdir"; else unset WIZARDRY_DIR; fi
  
  assert_success || return 1
  assert_output_contains "leap-to called with: 5" || return 1
}

run_test_case "parse building loop skips numeric args (banish 5)" test_parse_building_skips_numeric_args
run_test_case "parse doesn't exec functions (prevents infinite recursion)" test_parse_doesnt_exec_functions
run_test_case "parse is POSIX compliant (no type command)" test_parse_posix_compliant
run_test_case "parse building loop skips flags" test_parse_building_skips_flags
run_test_case "parse multi-word with numeric arg" test_parse_multiword_with_number

finish_tests
