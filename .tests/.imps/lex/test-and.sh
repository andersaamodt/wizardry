#!/bin/sh
# Tests for the 'and' linking word imp

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

test_and_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/and" ]
}

test_and_continues_on_success() {
  run_spell spells/.imps/lex/and "true" "" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

test_and_stops_on_failure() {
  run_spell spells/.imps/lex/and "false" "" echo shouldnt_run
  assert_failure || return 1
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="and continued after failure"
      return 1
      ;;
  esac
}

test_and_no_prior_command() {
  run_spell spells/.imps/lex/and "" "" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

run_test_case "and is executable" test_and_is_executable
run_test_case "and continues on success" test_and_continues_on_success
run_test_case "and stops on failure" test_and_stops_on_failure
run_test_case "and with no prior command" test_and_no_prior_command

finish_tests
