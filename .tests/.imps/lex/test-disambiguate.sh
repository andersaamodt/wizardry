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
  run_spell spells/.imps/lex/disambiguate
  assert_success || return 1
}

test_disambiguate_runs_single_command() {
  run_spell spells/.imps/lex/disambiguate echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

run_test_case "disambiguate is executable" test_disambiguate_is_executable
run_test_case "disambiguate with no args succeeds" test_disambiguate_no_args_succeeds
run_test_case "disambiguate runs single command" test_disambiguate_runs_single_command

finish_tests
