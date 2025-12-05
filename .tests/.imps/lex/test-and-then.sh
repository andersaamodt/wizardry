#!/bin/sh
# Tests for the 'and-then' linking word imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_and_then_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/and-then" ]
}

test_and_then_continues_on_success() {
  run_spell spells/.imps/lex/and-then "true" "" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

test_and_then_stops_on_failure() {
  run_spell spells/.imps/lex/and-then "false" "" echo shouldnt_run
  assert_failure || return 1
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="and-then continued after failure"
      return 1
      ;;
  esac
}

test_and_then_no_prior_command() {
  run_spell spells/.imps/lex/and-then "" "" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

run_test_case "and-then is executable" test_and_then_is_executable
run_test_case "and-then continues on success" test_and_then_continues_on_success
run_test_case "and-then stops on failure" test_and_then_stops_on_failure
run_test_case "and-then with no prior command" test_and_then_no_prior_command

finish_tests
