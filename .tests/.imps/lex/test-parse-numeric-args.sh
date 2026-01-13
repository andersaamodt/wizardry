#!/bin/sh
# Tests for parse handling of numeric arguments
# These tests verify the fixes for bugs where numeric arguments
# were incorrectly treated as part of command names

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Test that numeric arguments don't get concatenated into command names
test_parse_skips_numeric_args() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  # Create a spell called "banish" that echoes its arguments
  cat > "$test_spell_dir/banish" <<'EOF'
#!/bin/sh
printf 'banish called with: [%s]\n' "$*"
EOF
  chmod +x "$test_spell_dir/banish"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Call parse with "banish 5" - should call banish with arg "5", not look for "banish-5"
  run_spell "spells/.imps/lex/parse" "banish" "5"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "banish called with: [5]" || return 1
}

# Test that flags don't get concatenated into command names
test_parse_skips_flags() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  # Create a spell called "echo" that shows its arguments
  cat > "$test_spell_dir/myecho" <<'EOF'
#!/bin/sh
printf 'myecho args: [%s]\n' "$*"
EOF
  chmod +x "$test_spell_dir/myecho"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Call parse with "myecho --flag arg" - should call myecho with "--flag arg", not look for "myecho--flag-arg"
  run_spell "spells/.imps/lex/parse" "myecho" "--flag" "arg"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "myecho args: [--flag arg]" || return 1
}

# Test multi-word command with numeric argument
test_parse_multiword_with_numeric() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  # Create a multi-word spell
  cat > "$test_spell_dir/jump-to" <<'EOF'
#!/bin/sh
printf 'jump-to called with: [%s]\n' "$*"
EOF
  chmod +x "$test_spell_dir/jump-to"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  # Call parse with "jump to 5" - should call jump-to with arg "5", not look for "jump-to-5"
  run_spell "spells/.imps/lex/parse" "jump" "to" "5"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "jump-to called with: [5]" || return 1
}

# Run all tests
run_test_case "parse skips numeric arguments" test_parse_skips_numeric_args
run_test_case "parse skips flags" test_parse_skips_flags
run_test_case "parse handles multi-word command with numeric arg" test_parse_multiword_with_numeric

finish_tests
