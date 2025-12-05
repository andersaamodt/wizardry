#!/bin/sh
# Tests for the 'test-assert-success' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_test_assert_success_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/test-assert-success" ]
}

test_test_assert_success_succeeds_on_zero() {
  STATUS=0
  export STATUS
  run_spell spells/.imps/test/test-assert-success
  assert_success
}

run_test_case "test-assert-success is executable" test_test_assert_success_exists
run_test_case "test-assert-success succeeds on zero" test_test_assert_success_succeeds_on_zero

finish_tests
