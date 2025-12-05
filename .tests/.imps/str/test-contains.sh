#!/bin/sh
# Tests for the 'contains' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_contains_finds_substring() {
  run_spell spells/.imps/str/contains "hello world" "wor"
  assert_success
}

test_contains_rejects_missing() {
  run_spell spells/.imps/str/contains "hello world" "xyz"
  assert_failure
}

run_test_case "contains finds substring" test_contains_finds_substring
run_test_case "contains rejects missing substring" test_contains_rejects_missing

finish_tests
