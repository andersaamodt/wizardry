#!/bin/sh
# Tests for the 'ok' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_ok_succeeds_when_command_succeeds() {
  _run_spell spells/.imps/out/ok true
  _assert_success
}

test_ok_fails_when_command_fails() {
  _run_spell spells/.imps/out/ok false
  _assert_failure
}

_run_test_case "ok succeeds when command succeeds" test_ok_succeeds_when_command_succeeds
_run_test_case "ok fails when command fails" test_ok_fails_when_command_fails

_finish_tests
