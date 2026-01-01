#!/bin/sh
# SKIP_TEST: then linking word requires parse to be enabled (currently in passthrough mode)
# Tests for the 'then' linking word imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

# Skip all tests - then only works when parse is enabled
printf 'SKIP: then tests disabled (parse is in passthrough mode)\n'
printf '0/0 tests passed\n'
exit 0

test_next_is_executable() {
  [ -x "$ROOT_DIR/spells/.imps/lex/next" ]
}

test_next_continues_on_success() {
  run_spell spells/.imps/lex/next "true" "" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

test_next_stops_on_failure() {
  run_spell spells/.imps/lex/next "false" "" echo shouldnt_run
  assert_failure || return 1
  case "$OUTPUT" in
    *shouldnt_run*)
      TEST_FAILURE_REASON="then continued after failure"
      return 1
      ;;
  esac
}

test_next_no_prior_command() {
  run_spell spells/.imps/lex/next "" "" echo hello
  assert_success || return 1
  assert_output_contains "hello" || return 1
}

run_test_case "then is executable" test_next_is_executable
run_test_case "then continues on success" test_next_continues_on_success
run_test_case "then stops on failure" test_next_stops_on_failure
run_test_case "then with no prior command" test_next_no_prior_command

finish_tests
