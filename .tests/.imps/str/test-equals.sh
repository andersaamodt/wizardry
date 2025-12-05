#!/bin/sh
# Tests for the 'equals' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_equals_same_string() {
  run_spell spells/.imps/str/equals "hello" "hello"
  assert_success
}

test_equals_different_strings() {
  run_spell spells/.imps/str/equals "hello" "world"
  assert_failure
}

run_test_case "equals accepts same string" test_equals_same_string
run_test_case "equals rejects different strings" test_equals_different_strings

finish_tests
