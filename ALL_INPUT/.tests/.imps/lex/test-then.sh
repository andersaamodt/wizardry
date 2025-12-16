#!/bin/sh
# Tests for the 'then' linking word imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_then_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/then" ]
}

test_then_continues_on_success() {
  _run_spell spells/.imps/lex/then "true" "" echo hello
  _assert_success || return 1
  _assert_output_contains "hello" || return 1
}

test_then_stops_on_failure() {
  _run_spell spells/.imps/lex/then "false" "" echo shouldnt_run
  _assert_failure || return 1
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="then continued after failure"
      return 1
      ;;
  esac
}

test_then_no_prior_command() {
  _run_spell spells/.imps/lex/then "" "" echo hello
  _assert_success || return 1
  _assert_output_contains "hello" || return 1
}

_run_test_case "then is executable" test_then_is_executable
_run_test_case "then continues on success" test_then_continues_on_success
_run_test_case "then stops on failure" test_then_stops_on_failure
_run_test_case "then with no prior command" test_then_no_prior_command

_finish_tests
