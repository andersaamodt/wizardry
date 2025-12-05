#!/bin/sh
# Tests for the 'test-assert-failure' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_test_assert_failure_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/test-assert-failure" ]
}

test_test_assert_failure_succeeds_on_nonzero() {
  STATUS=1
  export STATUS
  run_spell spells/.imps/test/test-assert-failure
  assert_success
}

run_test_case "test-assert-failure is executable" test_test_assert_failure_exists
run_test_case "test-assert-failure succeeds on nonzero" test_test_assert_failure_succeeds_on_nonzero

finish_tests
