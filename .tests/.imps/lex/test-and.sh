#!/bin/sh
# Tests for the 'and' linking word imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_and_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/and" ]
}

test_and_continues_on_success() {
  _run_spell spells/.imps/lex/and "true" "" echo hello
  _assert_success || return 1
  _assert_output_contains "hello" || return 1
}

test_and_stops_on_failure() {
  _run_spell spells/.imps/lex/and "false" "" echo shouldnt_run
  _assert_failure || return 1
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="and continued after failure"
      return 1
      ;;
  esac
}

test_and_no_prior_command() {
  _run_spell spells/.imps/lex/and "" "" echo hello
  _assert_success || return 1
  _assert_output_contains "hello" || return 1
}

_run_test_case "and is executable" test_and_is_executable
_run_test_case "and continues on success" test_and_continues_on_success
_run_test_case "and stops on failure" test_and_stops_on_failure
_run_test_case "and with no prior command" test_and_no_prior_command

_finish_tests
