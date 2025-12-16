#!/bin/sh
# Tests for the 'disambiguate' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_disambiguate_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/disambiguate" ]
}

test_disambiguate_no_args_succeeds() {
  _run_spell spells/.imps/lex/disambiguate
  _assert_success || return 1
}

test_disambiguate_runs_single_command() {
  _run_spell spells/.imps/lex/disambiguate echo hello
  _assert_success || return 1
  _assert_output_contains "hello" || return 1
}

_run_test_case "disambiguate is executable" test_disambiguate_is_executable
_run_test_case "disambiguate with no args succeeds" test_disambiguate_no_args_succeeds
_run_test_case "disambiguate runs single command" test_disambiguate_runs_single_command

_finish_tests
