#!/bin/sh
# Tests for grammar linking word imps (then, and, or, into, to, from)

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

# --- then imp tests ---

test_then_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/then" ]
}

test_then_executes_command() {
  run_spell "spells/.imps/lex/then" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

test_then_no_args_succeeds() {
  run_spell "spells/.imps/lex/then"
  assert_success || return 1
}

# --- and imp tests ---

test_and_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/and" ]
}

test_and_executes_command() {
  run_spell "spells/.imps/lex/and" echo world
  assert_success || return 1
  assert_output_contains "world" || return 1
}

# --- or imp tests ---

test_or_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/or" ]
}

test_or_executes_command() {
  run_spell "spells/.imps/lex/or" echo fallback
  assert_success || return 1
  assert_output_contains "fallback" || return 1
}

# --- into imp tests ---

test_into_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/into" ]
}

test_into_reorders_args() {
  tmp=$(make_tempdir)
  mkdir -p "$tmp/target"
  echo "content" > "$tmp/source.txt"
  
  run_spell "spells/.imps/lex/into" "$tmp/target" cp "$tmp/source.txt"
  assert_success || return 1
  
  if [ ! -f "$tmp/target/source.txt" ]; then
    TEST_FAILURE_REASON="File not copied to target directory"
    return 1
  fi
}

test_into_requires_target_and_cmd() {
  run_spell "spells/.imps/lex/into" /tmp
  assert_failure || return 1
}

# --- to imp tests ---

test_to_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/to" ]
}

test_to_reorders_args() {
  tmp=$(make_tempdir)
  echo "content" > "$tmp/source.txt"
  
  run_spell "spells/.imps/lex/to" "$tmp/dest.txt" cp "$tmp/source.txt"
  assert_success || return 1
  
  if [ ! -f "$tmp/dest.txt" ]; then
    TEST_FAILURE_REASON="File not copied to destination"
    return 1
  fi
}

# --- from imp tests ---

test_from_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/from" ]
}

test_from_reorders_args() {
  tmp=$(make_tempdir)
  echo "source content" > "$tmp/source.txt"
  
  run_spell "spells/.imps/lex/from" "$tmp/source.txt" cp "$tmp/dest.txt"
  assert_success || return 1
  
  if [ ! -f "$tmp/dest.txt" ]; then
    TEST_FAILURE_REASON="File not copied from source"
    return 1
  fi
}

test_from_requires_source_and_cmd() {
  run_spell "spells/.imps/lex/from" /tmp
  assert_failure || return 1
}

# Run all tests
run_test_case "then is executable" test_then_is_executable
run_test_case "then executes command" test_then_executes_command
run_test_case "then with no args succeeds" test_then_no_args_succeeds
run_test_case "and is executable" test_and_is_executable
run_test_case "and executes command" test_and_executes_command
run_test_case "or is executable" test_or_is_executable
run_test_case "or executes command" test_or_executes_command
run_test_case "into is executable" test_into_is_executable
run_test_case "into reorders arguments" test_into_reorders_args
run_test_case "into requires target and cmd" test_into_requires_target_and_cmd
run_test_case "to is executable" test_to_is_executable
run_test_case "to reorders arguments" test_to_reorders_args
run_test_case "from is executable" test_from_is_executable
run_test_case "from reorders arguments" test_from_reorders_args
run_test_case "from requires source and cmd" test_from_requires_source_and_cmd
finish_tests
