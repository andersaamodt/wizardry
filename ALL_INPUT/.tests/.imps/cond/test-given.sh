#!/bin/sh
# Tests for the 'given' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_given_succeeds_for_nonempty() {
  _run_spell spells/.imps/cond/given "something"
  _assert_success
}

test_given_fails_for_empty() {
  _run_spell spells/.imps/cond/given ""
  _assert_failure
}

_run_test_case "given succeeds for non-empty string" test_given_succeeds_for_nonempty
_run_test_case "given fails for empty string" test_given_fails_for_empty

_finish_tests
