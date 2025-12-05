#!/bin/sh
# Tests for the 'then' linking word imp

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_then_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/then" ]
}

test_then_continues_on_success() {
  run_spell spells/.imps/lex/then "true" "" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

test_then_stops_on_failure() {
  run_spell spells/.imps/lex/then "false" "" echo shouldnt_run
  assert_failure || return 1
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="then continued after failure"
      return 1
      ;;
  esac
}

test_then_no_prior_command() {
  run_spell spells/.imps/lex/then "" "" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

run_test_case "then is executable" test_then_is_executable
run_test_case "then continues on success" test_then_continues_on_success
run_test_case "then stops on failure" test_then_stops_on_failure
run_test_case "then with no prior command" test_then_no_prior_command

finish_tests
