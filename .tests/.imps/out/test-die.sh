#!/bin/sh
# Tests for the 'die' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_die_exits_with_message() {
  _run_spell spells/.imps/out/die "fatal error"
  _assert_failure
  _assert_error_contains "fatal error"
}

test_die_accepts_custom_exit_code() {
  _run_spell spells/.imps/out/die 42 "custom code"
  [ "$STATUS" -eq 42 ] || { TEST_FAILURE_REASON="expected status 42, got $STATUS"; return 1; }
}

_run_test_case "die exits with message" test_die_exits_with_message
_run_test_case "die accepts custom exit code" test_die_accepts_custom_exit_code

_finish_tests
