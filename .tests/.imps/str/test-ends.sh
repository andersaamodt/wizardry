#!/bin/sh
# Tests for the 'ends' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_ends_with() {
  _run_spell spells/.imps/str/ends "hello world" "world"
  _assert_success
}

test_ends_not() {
  _run_spell spells/.imps/str/ends "hello world" "hello"
  _assert_failure
}

_run_test_case "ends matches suffix" test_ends_with
_run_test_case "ends rejects non-suffix" test_ends_not

_finish_tests
