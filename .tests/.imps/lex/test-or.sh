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
  run_spell spells/.imps/lex/or "false" "" echo fallback
  assert_success || return 1
  assert_output_contains "fallback" || return 1
}

test_or_skips_on_success() {
  run_spell spells/.imps/lex/or "true" "" echo shouldnt_appear
  assert_success || return 1
  case "$OUTPUT" in
    *shouldnt_appear*)
      TEST_FAILURE_REASON="or fallback executed when command succeeded"
      return 1
      ;;
  esac
}

test_or_no_prior_command_continues() {
  run_spell spells/.imps/lex/or "" "" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

run_test_case "or is executable" test_or_is_executable
run_test_case "or continues on failure" test_or_continues_on_failure
run_test_case "or skips on success" test_or_skips_on_success
run_test_case "or with no prior command continues" test_or_no_prior_command_continues

finish_tests
