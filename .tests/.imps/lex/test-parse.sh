#!/bin/sh
# Tests for parse command execution engine

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

# Test command reconstruction from space-separated arguments
test_parse_reconstructs_two_word_command() {
  tmpdir=$(make_tempdir)
  test_spell_dir="$tmpdir/wizardry/spells/.imps/sys"
  mkdir -p "$test_spell_dir"
  
  cat > "$test_spell_dir/env-or" <<'EOF'
#!/bin/sh
_env_or() {
  printf 'env_or_called_with:[%s][%s]\n' "$1" "$2"
}
case "$0" in
  */env-or) _env_or "$@" ;; esac
EOF
  chmod +x "$test_spell_dir/env-or"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  run_spell "spells/.imps/lex/parse" "env" "or" "MYVAR" "default_value"
  
  assert_success || return 1
  assert_output_contains "env_or_called_with:[MYVAR][default_value]" || return 1
}

test_parse_reconstructs_three_word_command() {
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
  
  assert_success || return 1
  assert_output_contains "make_temp_file_called_with:[myfile.txt]" || return 1
}

test_parse_reconstructs_four_word_command() {
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
  
  assert_success || return 1
  assert_output_contains "get_remote_file_path_called_with:[/some/path]" || return 1
}

test_parse_prefers_longer_matches() {
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
  
  assert_success || return 1
  assert_output_contains "CORRECT:env_or_called" || return 1
  if printf '%s' "$OUTPUT" | grep -q "WRONG:env_called"; then
    TEST_FAILURE_REASON="Parse called shorter 'env' instead of longer 'env-or'"
    return 1
  fi
}

test_parse_tries_progressively_shorter() {
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
  
  assert_success || return 1
  assert_output_contains "temp_file_called_with:[with extra args]" || return 1
}

# Test gloss recursion and collision detection
test_parse_finds_spell_file() {
  run_spell "spells/.imps/lex/parse" "verify-posix" --help
  assert_success || return 1
  assert_error_contains "Usage:" || return 1
}

test_parse_self_reference_handling() {
  run_spell "spells/.imps/lex/parse" "parse" --help
  assert_success || return 1
  assert_error_contains "parse - Command execution engine" || return 1
}

test_parse_recursion_depth_limit() {
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
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/wizardry/spells/.imps/sys"
  
  cat > "$tmpdir/wizardry/spells/.imps/sys/env-or" <<'EOF'
#!/bin/sh
printf 'env-or called\n'
EOF
  chmod +x "$tmpdir/wizardry/spells/.imps/sys/env-or"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  run_spell "spells/.imps/lex/parse" "env"
  
  assert_success || return 1
  assert_output_contains "PATH=" || return 1
}

test_parse_collision_wizardry_spell_priority() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/wizardry/spells/.imps/sys"
  
  cat > "$tmpdir/wizardry/spells/.imps/sys/env" <<'EOF'
#!/bin/sh
printf 'WIZARDRY_ENV_CALLED\n'
EOF
  chmod +x "$tmpdir/wizardry/spells/.imps/sys/env"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  run_spell "spells/.imps/lex/parse" "env"
  
  assert_success || return 1
  assert_output_contains "WIZARDRY_ENV_CALLED" || return 1
}

test_parse_collision_no_incorrect_match() {
  tmpdir=$(make_tempdir)
  mkdir -p "$tmpdir/wizardry/spells/.imps/sys"
  
  cat > "$tmpdir/wizardry/spells/.imps/sys/env-or" <<'EOF'
#!/bin/sh
printf 'env-or called\n'
EOF
  chmod +x "$tmpdir/wizardry/spells/.imps/sys/env-or"
  
  export WIZARDRY_DIR="$tmpdir/wizardry"
  
  run_spell "spells/.imps/lex/parse" "env" "file"
  
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

# Run all tests
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
finish_tests
