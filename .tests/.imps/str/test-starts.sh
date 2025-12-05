#!/bin/sh
# Tests for the 'starts' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_starts_with() {
  _run_spell spells/.imps/str/starts "hello world" "hello"
  _assert_success
}

test_starts_not() {
  _run_spell spells/.imps/str/starts "hello world" "world"
  _assert_failure
}

_run_test_case "starts matches prefix" test_starts_with
_run_test_case "starts rejects non-prefix" test_starts_not

_finish_tests
