#!/bin/sh
# Tests for the 'or' linking word imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_or_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/or" ]
}

test_or_continues_on_failure() {
  _run_spell spells/.imps/lex/or "false" "" echo fallback
  _assert_success || return 1
  _assert_output_contains "fallback" || return 1
}

test_or_skips_on_success() {
  _run_spell spells/.imps/lex/or "true" "" echo shouldnt_appear
  _assert_success || return 1
  case "$OUTPUT" in
    *shouldnt_appear*)
      TEST_FAILURE_REASON="or fallback executed when command succeeded"
      return 1
      ;;
  esac
}

test_or_no_prior_command_continues() {
  _run_spell spells/.imps/lex/or "" "" echo hello
  _assert_success || return 1
  _assert_output_contains "hello" || return 1
}

_run_test_case "or is executable" test_or_is_executable
_run_test_case "or continues on failure" test_or_continues_on_failure
_run_test_case "or skips on success" test_or_skips_on_success
_run_test_case "or with no prior command continues" test_or_no_prior_command_continues

_finish_tests
