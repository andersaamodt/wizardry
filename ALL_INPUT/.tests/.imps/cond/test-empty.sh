#!/bin/sh
# Tests for the 'empty' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_empty_succeeds_for_empty() {
  _run_spell spells/.imps/cond/empty ""
  _assert_success
}

test_empty_fails_for_nonempty() {
  _run_spell spells/.imps/cond/empty "something"
  _assert_failure
}

_run_test_case "empty succeeds for empty string" test_empty_succeeds_for_empty
_run_test_case "empty fails for non-empty string" test_empty_fails_for_nonempty

_finish_tests
