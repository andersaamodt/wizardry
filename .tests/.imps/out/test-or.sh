#!/bin/sh
# Tests for the 'or' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_or_first() {
  run_spell spells/.imps/out/or "first" "second"
  assert_success
  assert_output_contains "first"
}

test_or_second() {
  run_spell spells/.imps/out/or "" "second"
  assert_success
  assert_output_contains "second"
}

test_or_fails_both_empty() {
  run_spell spells/.imps/out/or "" ""
  assert_failure
}

run_test_case "or returns first non-empty" test_or_first
run_test_case "or returns second if first empty" test_or_second
run_test_case "or fails if both empty" test_or_fails_both_empty

finish_tests
