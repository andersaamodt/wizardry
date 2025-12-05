#!/bin/sh
# Tests for the 'test-assert-error-contains' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_test_assert_error_contains_exists() {
  [ -x "$ROOT_DIR/spells/.imps/test/test-assert-error-contains" ]
}

test_test_assert_error_contains_finds_substring() {
  ERROR="this is an error message"
  export ERROR
  run_spell spells/.imps/test/test-assert-error-contains "error"
  assert_success
}

run_test_case "test-assert-error-contains is executable" test_test_assert_error_contains_exists
run_test_case "test-assert-error-contains finds substring" test_test_assert_error_contains_finds_substring

finish_tests
