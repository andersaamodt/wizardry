#!/bin/sh
# Tests for the 'disambiguate' imp

set -eu

# Source test harness
_test_dir=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ "$_test_dir" != "/" ] && [ ! -d "$_test_dir/spells" ]; do _test_dir=$(dirname "$_test_dir"); done
# shellcheck source=/dev/null
. "$_test_dir/spells/.imps/test/src-test-harness"

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
