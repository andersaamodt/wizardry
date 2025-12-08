#!/bin/sh
# Tests for the 'warn' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_warn_to_stderr() {
  _run_spell spells/.imps/out/warn "warning message"
  _assert_success
  _assert_error_contains "warning message"
}

test_warn_succeeds_with_empty_message() {
  _run_spell spells/.imps/out/warn ""
  _assert_success
}

_run_test_case "warn outputs to stderr" test_warn_to_stderr
_run_test_case "warn succeeds with empty message" test_warn_succeeds_with_empty_message

_finish_tests
