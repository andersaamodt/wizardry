#!/bin/sh
# Tests for the 'differs' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_differs_different_strings() {
  run_spell spells/.imps/str/differs "hello" "world"
  assert_success
}

test_differs_same_string() {
  run_spell spells/.imps/str/differs "hello" "hello"
  assert_failure
}

run_test_case "differs accepts different strings" test_differs_different_strings
run_test_case "differs rejects same string" test_differs_same_string

finish_tests
