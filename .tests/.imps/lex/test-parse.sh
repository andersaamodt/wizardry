#!/bin/sh
# Tests for parse recursive grammar parser

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/test-common.sh" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/test-common.sh"

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
  run_spell "spells/.imps/lex/parse" false or echo fallback
  assert_success || return 1
  assert_output_contains "fallback" || return 1
}

test_parse_imperative_or_success_skips() {
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
  run_spell "spells/.imps/lex/parse" echo first and then echo second
  assert_success || return 1
  assert_output_contains "first" || return 1
  assert_output_contains "second" || return 1
}

test_parse_and_then_stops_on_failure() {
  run_spell "spells/.imps/lex/parse" false and then echo shouldnt_run
  assert_failure || return 1
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="and-then continued after failure"
      return 1
      ;;
  esac
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
finish_tests
