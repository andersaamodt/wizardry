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
  run_spell spells/.imps/str/starts "hello world" "hello"
  assert_success
}

test_starts_not() {
  run_spell spells/.imps/str/starts "hello world" "world"
  assert_failure
}

run_test_case "starts matches prefix" test_starts_with
run_test_case "starts rejects non-prefix" test_starts_not

finish_tests
