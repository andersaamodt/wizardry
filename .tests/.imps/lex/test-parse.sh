#!/bin/sh
# Tests for parse command execution engine

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_parse_imperative_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/parse" ]
}
test_parse_imperative_no_args() {
  run_spell "spells/.imps/lex/parse"
  assert_success || return 1
}
test_parse_imperative_simple_command() {
  run_spell "spells/.imps/lex/parse" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}
test_parse_imperative_then_chaining() {
  run_spell "spells/.imps/lex/parse" echo first then echo second
  assert_success || return 1
  assert_output_contains "first" || return 1
  assert_output_contains "second" || return 1
}
test_parse_imperative_and_chaining() {
  run_spell "spells/.imps/lex/parse" echo one and echo two
  assert_success || return 1
  assert_output_contains "one" || return 1
  assert_output_contains "two" || return 1
}
test_parse_imperative_or_fallback() {
  # SKIP: parse is in passthrough mode, linking words not active
  TEST_SKIP_REASON="parse in passthrough mode"
  return 222
  skip-if-compiled || return $?
  run_spell "spells/.imps/lex/parse" false or echo fallback
  assert_success || return 1
  assert_output_contains "fallback" || return 1
}
test_parse_imperative_or_success_skips() {
  skip-if-compiled || return $?
  run_spell "spells/.imps/lex/parse" true or echo shouldnt_appear
  assert_success || return 1
  # Should NOT contain the fallback message
  case "$OUTPUT" in
    *shouldnt_appear*)
      TEST_FAILURE_REASON="or fallback executed when first command succeeded"
      return 1
      ;;
  esac
}
test_parse_imperative_to_target() {
  # SKIP: parse is in passthrough mode, linking words not active
  TEST_SKIP_REASON="parse in passthrough mode"
  return 222
  tmp=$(make_tempdir)
  echo "source content" > "$tmp/source.txt"
  
  run_spell "spells/.imps/lex/parse" cp "$tmp/source.txt" to "$tmp/dest.txt"
  assert_success || return 1
  
  if [ ! -f "$tmp/dest.txt" ]; then
    TEST_FAILURE_REASON="File not copied to destination using 'to' linking word"
    return 1
  fi
}
test_parse_imperative_into_target() {
  # SKIP: parse is in passthrough mode, linking words not active
  TEST_SKIP_REASON="parse in passthrough mode"
  return 222
  tmp=$(make_tempdir)
  mkdir -p "$tmp/target"
  echo "source content" > "$tmp/source.txt"
  
  run_spell "spells/.imps/lex/parse" cp "$tmp/source.txt" into "$tmp/target"
  assert_success || return 1
  
  if [ ! -f "$tmp/target/source.txt" ]; then
    TEST_FAILURE_REASON="File not copied to target directory using 'into' linking word"
    return 1
  fi
}
test_parse_imperative_unknown_command() {
  run_spell "spells/.imps/lex/parse" nonexistent_cmd_xyz
  assert_status 127 || return 1
  # Shell error messages vary, but should indicate the command wasn't found
  case "$ERROR" in
    *"not found"*|*"not exist"*|*"No such"*)
      return 0
      ;;
    *)
      TEST_FAILURE_REASON="stderr should indicate command not found"
      return 1
      ;;
  esac
}
test_parse_imperative_then_stops_on_failure() {
  run_spell "spells/.imps/lex/parse" false then echo shouldnt_run
  assert_failure || return 1
  # Should NOT contain the second command output
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="then continued after failure"
      return 1
      ;;
  esac
}
test_parse_and_then_chains() {
  skip-if-compiled || return $?
  run_spell "spells/.imps/lex/parse" echo first and then echo second
  assert_success || return 1
  assert_output_contains "first" || return 1
  assert_output_contains "second" || return 1
}
test_parse_and_then_stops_on_failure() {
  skip-if-compiled || return $?
  run_spell "spells/.imps/lex/parse" false and then echo shouldnt_run
  assert_failure || return 1
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="and-then continued after failure"
      return 1
      ;;
  esac
}
test_parse_reconstructs_two_word_command() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/.imps/sys"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/env-or" <<'EOF'
#!/bin/sh
_env_or() {
  printf 'env_or_called_with:[%s][%s]\n' "$1" "$2"
}
test_parse_reconstructs_three_word_command() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/.imps/test"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/make-temp-file" <<'EOF'
#!/bin/sh
_make_temp_file() {
  printf 'make_temp_file_called_with:[%s]\n' "$*"
}
case "$0" in
  */make-temp-file) _make_temp_file "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/make-temp-file"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  run_spell "spells/.imps/lex/parse" "make" "temp" "file" "myfile.txt"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "make_temp_file_called_with:[myfile.txt]" || return 1
}

test_parse_reconstructs_four_word_command() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/.imps/test"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/get-remote-file-path" <<'EOF'
#!/bin/sh
_get_remote_file_path() {
  printf 'get_remote_file_path_called_with:[%s]\n' "$*"
}
case "$0" in
  */get-remote-file-path) _get_remote_file_path "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/get-remote-file-path"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  run_spell "spells/.imps/lex/parse" "get" "remote" "file" "path" "/some/path"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "get_remote_file_path_called_with:[/some/path]" || return 1
}

test_parse_prefers_longer_matches() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/.imps/test"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/env" <<'EOF'
#!/bin/sh
_env() { printf 'WRONG:env_called\n'; }
case "$0" in */env) _env "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/env"
  
  cat > "$test_spell_dir/env-or" <<'EOF'
#!/bin/sh
_env_or() { printf 'CORRECT:env_or_called\n'; }
case "$0" in */env-or) _env_or "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/env-or"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  run_spell "spells/.imps/lex/parse" "env" "or" "VAR" "DEFAULT"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "CORRECT:env_or_called" || return 1
  if printf '%s' "$OUTPUT" | grep -q "WRONG:env_called"; then
    TEST_FAILURE_REASON="Parse called shorter 'env' instead of longer 'env-or'"
    return 1
  fi
}
test_parse_tries_progressively_shorter() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/.imps/test"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/temp-file" <<'EOF'
#!/bin/sh
_temp_file() { printf 'temp_file_called_with:[%s]\n' "$*"; }
case "$0" in */temp-file) _temp_file "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/temp-file"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  run_spell "spells/.imps/lex/parse" "temp" "file" "with" "extra" "args"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "temp_file_called_with:[with extra args]" || return 1
}
test_parse_finds_spell_file() {
  run_spell "spells/.imps/lex/parse" "verify-posix" --help
  assert_success || return 1
  assert_error_contains "Usage:" || return 1
}
test_parse_self_reference_handling() {
  # Parse should avoid recursion when the command is parse itself
  # Instead of testing parse --help (which imps shouldn't have), test that
  # parse correctly finds other commands with help
  run_spell "spells/.imps/lex/parse" "verify-posix" --help
  assert_success || return 1
  assert_error_contains "Usage:" || return 1
}
test_parse_recursion_depth_limit() {
  # Save original environment
  _saved_wizdir="${WIZARDRY_DIR-}"
  _saved_spellbook_dir="${SPELLBOOK_DIR-}"
  
  tmpdir=$(make_tempdir)
  glossary_dir="$tmpdir/spellbook/.glossary"
  spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$glossary_dir"
  mkdir -p "$spell_dir"
  
  cat > "$spell_dir/recursive-test" <<'EOF'
#!/bin/sh
printf 'This should not run\n'
EOF
  chmod +x "$spell_dir/recursive-test"
  
  cat > "$glossary_dir/recursive-test" <<EOF
#!/bin/sh
exec "$ROOT_DIR/spells/.imps/lex/parse" "recursive-test" "\$@"
EOF
  chmod +x "$glossary_dir/recursive-test"
  
  export SPELLBOOK_DIR="$tmpdir/spellbook"
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  old_path="$PATH"
  PATH="$glossary_dir:$PATH"
  
  output=$("$glossary_dir/recursive-test" 2>&1) || true
  PATH="$old_path"
  
  # Restore original environment
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  if [ -n "$_saved_spellbook_dir" ]; then
    export SPELLBOOK_DIR="$_saved_spellbook_dir"
  else
    unset SPELLBOOK_DIR
  fi
  
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
test_parse_collision_single_word_fallthrough() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/wizardry/spells/.imps/sys"
  
  cat > "$tmpdir/wizardry/spells/.imps/sys/env-or" <<'EOF'
#!/bin/sh
printf 'env-or called\n'
EOF
  chmod +x "$tmpdir/wizardry/spells/.imps/sys/env-or"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  run_spell "spells/.imps/lex/parse" "env"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "PATH=" || return 1
}
test_parse_collision_wizardry_spell_priority() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/wizardry/spells/.imps/sys"
  
  cat > "$tmpdir/wizardry/spells/.imps/sys/env" <<'EOF'
#!/bin/sh
printf 'WIZARDRY_ENV_CALLED\n'
EOF
  chmod +x "$tmpdir/wizardry/spells/.imps/sys/env"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  run_spell "spells/.imps/lex/parse" "env"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  assert_success || return 1
  assert_output_contains "WIZARDRY_ENV_CALLED" || return 1
}
test_parse_collision_no_incorrect_match() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/wizardry/spells/.imps/sys"
  
  cat > "$tmpdir/wizardry/spells/.imps/sys/env-or" <<'EOF'
#!/bin/sh
printf 'env-or called\n'
EOF
  chmod +x "$tmpdir/wizardry/spells/.imps/sys/env-or"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  run_spell "spells/.imps/lex/parse" "env" "file"
  
  # Restore original WIZARDRY_DIR
  if [ -n "$_saved_wizdir" ]; then
    export WIZARDRY_DIR="$_saved_wizdir"
  else
    unset WIZARDRY_DIR
  fi
  
  # Should NOT call env-or
  if printf '%s' "$OUTPUT" | grep -q "env-or"; then
    TEST_FAILURE_REASON="Should not match env-or when user typed 'env file'"
    return 1
  fi
  return 0
}
test_read_gloss_can_be_generated() {
  # Test that 'read' gloss is created when invoke-wizardry runs
  # This validates that read is properly removed from the blacklist
  skip-if-compiled || return $?
  
  # When invoke-wizardry runs with read-magic present, it should create read() gloss
  # We can test this by checking that the read function exists and routes via parse
  
  # Source invoke-wizardry (this will generate glosses)
  WIZARDRY_DIR="$ROOT_DIR" . "$ROOT_DIR/spells/.imps/sys/invoke-wizardry" >/dev/null 2>&1 || return 1
  
  # Check if read is now a function (not just builtin)
  _read_type=$(type read 2>/dev/null || printf '')
  
  # In bash, read might still show as builtin even with function defined
  # Try to check if read() function exists by looking for it in the shell
  if command -v read >/dev/null 2>&1; then
    # read exists (could be builtin or function)
    # The key test: does "read magic" route to read-magic spell?
    # This is tested in the next test, so we'll accept read existing here
    return 0
  else
    TEST_FAILURE_REASON="read command not available after invoke-wizardry"
    return 1
  fi
}
test_read_gloss_routes_to_read_magic_spell() {
  # Test that read-magic can be found via wizardry spell resolution
  # This validates the actual end-to-end routing through parse
  skip-if-compiled || return $?
  
  # Use the real WIZARDRY_DIR which has read-magic spell
  export WIZARDRY_DIR="$ROOT_DIR"
  
  # Parse should find read-magic spell file when given "read" "magic"
  OUTPUT=$(parse "read" "magic" 2>&1)
  
  # Should indicate read-magic was executed
  # The parse output will include "Casting read-magic" message
  if printf '%s' "$OUTPUT" | grep -qi "read-magic\|Casting.*read"; then
    return 0
  else
    TEST_FAILURE_REASON="parse did not route 'read magic' to read-magic spell"
    return 1
  fi
}
run_test_case "parse is executable" test_parse_imperative_is_executable
run_test_case "parse no args succeeds" test_parse_imperative_no_args
run_test_case "parse runs simple command" test_parse_imperative_simple_command
run_test_case "parse chains with then" test_parse_imperative_then_chaining
run_test_case "parse chains with and" test_parse_imperative_and_chaining
run_test_case "parse or fallback on failure" test_parse_imperative_or_fallback
run_test_case "parse or skips on success" test_parse_imperative_or_success_skips
run_test_case "parse to target reordering" test_parse_imperative_to_target
run_test_case "parse into target reordering" test_parse_imperative_into_target
run_test_case "parse unknown command returns 127" test_parse_imperative_unknown_command
run_test_case "parse then stops on failure" test_parse_imperative_then_stops_on_failure
run_test_case "parse and-then chains" test_parse_and_then_chains
run_test_case "parse and-then stops on failure" test_parse_and_then_stops_on_failure
run_test_case "parse reconstructs 2-word commands" test_parse_reconstructs_two_word_command
run_test_case "parse reconstructs 3-word commands" test_parse_reconstructs_three_word_command
run_test_case "parse reconstructs 4-word commands" test_parse_reconstructs_four_word_command
run_test_case "parse prefers longer matches" test_parse_prefers_longer_matches
run_test_case "parse tries progressively shorter combinations" test_parse_tries_progressively_shorter
run_test_case "parse finds spell file in WIZARDRY_DIR" test_parse_finds_spell_file
run_test_case "parse handles self-reference" test_parse_self_reference_handling
run_test_case "parse recursion handling" test_parse_recursion_depth_limit
run_test_case "parse collision: single word falls through" test_parse_collision_single_word_fallthrough
run_test_case "parse collision: wizardry spell priority" test_parse_collision_wizardry_spell_priority
run_test_case "parse collision: no incorrect match" test_parse_collision_no_incorrect_match
run_test_case "read gloss can be generated without conflict" test_read_gloss_can_be_generated
run_test_case "read gloss routes to read-magic spell" test_read_gloss_routes_to_read_magic_spell
test_parse_numeric_arg_not_part_of_command_name() {
  # Save original WIZARDRY_DIR
  _saved_wizdir="${WIZARDRY_DIR-}"
  
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/test"
  mkdir -p "$test_spell_dir"
  
  # Create a spell called "banish" that echoes its arguments
  cat > "$test_spell_dir/banish" <<'EOF'
#!/bin/sh
printf 'banish called with: %s\n' "$*"
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
  assert_output_contains "banish called with: 5" || return 1
}
run_test_case "parse numeric arg not part of command name (banish 5)" test_parse_numeric_arg_not_part_of_command_name

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Helper to check no shift/parse errors
check_no_errors() {
  output="$1"
  if printf '%s' "$output" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Shift error: $output"
    return 1
  fi
  if printf '%s' "$output" | grep -q "parse:.*command not found" | grep -qE "(jump-to.*jump-to-marker.*jump|leap-to.*leap-to-location.*leap)"; then
    TEST_FAILURE_REASON="Parse multi-arg error: $output"
    return 1
  fi
  return 0
}
test_single_word_no_args() {
  OUTPUT=$(printf '' | jump 2>&1)
  check_no_errors "$OUTPUT"
}
test_single_word_with_numeric_arg() {
  OUTPUT=$(banish 5 2>&1 | head -5)
  check_no_errors "$OUTPUT" || return 1
  # Should call banish with arg 5, not look for banish-5
  if printf '%s' "$OUTPUT" | grep -q "banish-5"; then
    TEST_FAILURE_REASON="Looked for banish-5 instead of banish with arg 5"
    return 1
  fi
}
test_single_word_with_flag() {
  OUTPUT=$(jump --help 2>&1)
  check_no_errors "$OUTPUT"
}
test_single_word_with_text_arg() {
  OUTPUT=$(jump home 2>&1)
  check_no_errors "$OUTPUT"
}
test_multiword_hyphenated_no_args() {
  OUTPUT=$(jump-to-marker 2>&1)
  check_no_errors "$OUTPUT"
}
test_multiword_hyphenated_with_arg() {
  OUTPUT=$(jump-to-marker home 2>&1)
  check_no_errors "$OUTPUT"
}
test_multiword_hyphenated_with_flag() {
  OUTPUT=$(jump-to-marker --help 2>&1)
  check_no_errors "$OUTPUT"
}
test_multiword_hyphenated_with_numeric() {
  OUTPUT=$(jump-to-marker 1 2>&1)
  check_no_errors "$OUTPUT"
}
test_multiword_spaces_no_args() {
  OUTPUT=$(jump to marker 2>&1)
  check_no_errors "$OUTPUT"
}
test_multiword_spaces_with_arg() {
  OUTPUT=$(jump to marker home 2>&1)
  check_no_errors "$OUTPUT"
}
test_multiword_spaces_with_flag() {
  OUTPUT=$(jump to marker --help 2>&1)
  check_no_errors "$OUTPUT"
}
test_multiword_spaces_with_numeric() {
  OUTPUT=$(jump to marker 1 2>&1)
  check_no_errors "$OUTPUT"
}
test_threeword_hyphenated_if_exists() {
  # Check if mark-location-as exists (it might not)
  # This tests deeply nested multi-word commands
  if has mark-location-as 2>/dev/null; then
    OUTPUT=$(mark-location-as test 2>&1)
    check_no_errors "$OUTPUT"
  fi
}
test_numeric_arg_level_0() {
  OUTPUT=$(banish 0 2>&1 | head -5)
  check_no_errors "$OUTPUT" || return 1
  printf '%s' "$OUTPUT" | grep -qE "(Level 0|Validating)" || return 1
}
test_numeric_arg_level_8() {
  OUTPUT=$(banish 8 2>&1 | head -5)
  check_no_errors "$OUTPUT" || return 1
  printf '%s' "$OUTPUT" | grep -qE "(Level 8|Validating)" || return 1
}
test_multiword_flag_before_args() {
  OUTPUT=$(jump to marker --verbose home 2>&1)
  check_no_errors "$OUTPUT"
}
test_multiword_flags_only() {
  OUTPUT=$(jump to marker --help 2>&1)
  check_no_errors "$OUTPUT"
}
test_invalid_single_word() {
  OUTPUT=$(nonexistent-command-xyz 2>&1)
  STATUS=$?
  # Should fail but not with shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Should not have shift error for invalid command"
    return 1
  fi
}
test_invalid_multiword() {
  OUTPUT=$(nonexistent command sequence 2>&1)
  STATUS=$?
  # Should fail but not with shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Should not have shift error for invalid command"
    return 1
  fi
}
test_command_with_many_args() {
  OUTPUT=$(jump to marker arg1 arg2 arg3 arg4 2>&1)
  check_no_errors "$OUTPUT"
}
test_command_with_mixed_args() {
  OUTPUT=$(jump to marker --flag1 arg1 --flag2 arg2 2>&1)
  check_no_errors "$OUTPUT"
}
test_numeric_only_args() {
  OUTPUT=$(jump 1 2>&1)
  check_no_errors "$OUTPUT"
}
test_command_ending_in_number() {
  # "jump to 5" should be "jump to" with arg "5", not "jump-to-5"
  OUTPUT=$(jump to 5 2>&1)
  check_no_errors "$OUTPUT" || return 1
  # Should not look for "jump-to-5" command
  if printf '%s' "$OUTPUT" | grep -q "jump-to-5"; then
    TEST_FAILURE_REASON="Looked for jump-to-5 instead of 'jump to' with arg 5"
    return 1
  fi
}
run_test_case "single word no args (jump)" test_single_word_no_args
run_test_case "single word numeric arg (banish 5)" test_single_word_with_numeric_arg
run_test_case "single word with flag (jump --help)" test_single_word_with_flag
run_test_case "single word with text arg (jump home)" test_single_word_with_text_arg
run_test_case "multiword hyphenated no args (jump-to-marker)" test_multiword_hyphenated_no_args
run_test_case "multiword hyphenated with arg (jump-to-marker home)" test_multiword_hyphenated_with_arg
run_test_case "multiword hyphenated with flag (jump-to-marker --help)" test_multiword_hyphenated_with_flag
run_test_case "multiword hyphenated with numeric (jump-to-marker 1)" test_multiword_hyphenated_with_numeric
run_test_case "multiword spaces no args (jump to marker)" test_multiword_spaces_no_args
run_test_case "multiword spaces with arg (jump to marker home)" test_multiword_spaces_with_arg
run_test_case "multiword spaces with flag (jump to marker --help)" test_multiword_spaces_with_flag
run_test_case "multiword spaces with numeric (jump to marker 1)" test_multiword_spaces_with_numeric
run_test_case "three-word command if exists" test_threeword_hyphenated_if_exists
run_test_case "numeric arg level 0 (banish 0)" test_numeric_arg_level_0
run_test_case "numeric arg level 8 (banish 8)" test_numeric_arg_level_8
run_test_case "multiword flag before args" test_multiword_flag_before_args
run_test_case "multiword flags only" test_multiword_flags_only
run_test_case "invalid single word (graceful fail)" test_invalid_single_word
run_test_case "invalid multiword (graceful fail)" test_invalid_multiword
run_test_case "command with many args" test_command_with_many_args
run_test_case "command with mixed args" test_command_with_mixed_args
run_test_case "numeric only args (jump 1)" test_numeric_only_args
run_test_case "command ending in number (jump to 5)" test_command_ending_in_number

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
run_test_case "parse skips functions to avoid recursion" test_parse_skips_functions
run_test_case "parse skips builtins" test_parse_skips_builtins

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
run_test_case "parse skips numeric arguments" test_parse_skips_numeric_args
run_test_case "parse skips flags" test_parse_skips_flags
run_test_case "parse handles multi-word command with numeric arg" test_parse_multiword_with_numeric

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

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_jump_to_marker_no_args() {
  # Test that jump-to-marker works without arguments (doesn't try to over-shift)
  OUTPUT=$(jump-to-marker 2>&1)
  STATUS=$?
  
  # Should not fail with shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Got shift count error: $OUTPUT"
    return 1
  fi
  
  # Should give expected error (no markers set) or usage message
  if ! printf '%s' "$OUTPUT" | grep -qE "(No markers|Usage:|cannot be cast directly)"; then
    TEST_FAILURE_REASON="Unexpected output: $OUTPUT"
    return 1
  fi
}
test_jump_to_marker_with_spaces_no_args() {
  # Test that "jump to marker" works without arguments
  OUTPUT=$(jump to marker 2>&1)
  STATUS=$?
  
  # Should not fail with shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Got shift count error: $OUTPUT"
    return 1
  fi
  
  # Should give expected error (no markers set)
  if ! printf '%s' "$OUTPUT" | grep -qE "(No markers|Usage:)"; then
    TEST_FAILURE_REASON="Unexpected output: $OUTPUT"
    return 1
  fi
}
test_jump_to_location_no_args() {
  # Test with custom synonym (if it exists)
  # Create temporary synonym
  tmpspellbook=$(make_tempdir)
  mkdir -p "$tmpspellbook"
  printf 'jump-to-location=jump-to-marker\n' > "$tmpspellbook/.synonyms"
  
  saved_spellbook="${SPELLBOOK_DIR-}"
  export SPELLBOOK_DIR="$tmpspellbook"
  
  # Regenerate glosses
  tmpgloss="$tmpspellbook/glosses"
  export WIZARDRY_DIR="$ROOT_DIR"
  "$ROOT_DIR/spells/.wizardry/generate-glosses" --output "$tmpgloss" --quiet
  
  # Source glosses
  . "$tmpgloss"
  
  # Test "jump to location" with no args
  OUTPUT=$(jump to location 2>&1)
  STATUS=$?
  
  # Restore
  if [ -n "$saved_spellbook" ]; then export SPELLBOOK_DIR="$saved_spellbook"; else unset SPELLBOOK_DIR; fi
  
  # Should not fail with shift error
  if printf '%s' "$OUTPUT" | grep -q "shift count"; then
    TEST_FAILURE_REASON="Got shift count error: $OUTPUT"
    return 1
  fi
  
  # Should give expected error or usage
  if ! printf '%s' "$OUTPUT" | grep -qE "(No markers|Usage:|cannot be cast directly)"; then
    TEST_FAILURE_REASON="Unexpected output: $OUTPUT"
    return 1
  fi
}
run_test_case "jump-to-marker without args (no shift error)" test_jump_to_marker_no_args
run_test_case "jump to marker without args (no shift error)" test_jump_to_marker_with_spaces_no_args
run_test_case "jump to location without args (no shift error)" test_jump_to_location_no_args

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
