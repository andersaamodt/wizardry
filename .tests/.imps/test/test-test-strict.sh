#!/bin/sh
# Tests for the 'test-strict' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_test_strict_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/test-strict" ]
}

test_test_strict_is_sourceable() {
  [ -f "$ROOT_DIR/spells/.imps/test/test-strict" ] || { TEST_FAILURE_REASON="file should exist"; return 1; }
}

run_test_case "test-strict is executable" test_test_strict_exists
run_test_case "test-strict is sourceable" test_test_strict_is_sourceable

finish_tests
