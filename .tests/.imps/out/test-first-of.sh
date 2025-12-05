#!/bin/sh
# Tests for the 'first-of' imp

# Locate the repository root so we can source test-bootstrap
# Start from this test's directory and walk upward until spells/.imps/test/test-bootstrap is found
# shellcheck disable=SC2034
# (SC2034: test_root is used by sourced helpers)
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_first_of_first() {
  run_spell spells/.imps/out/first-of "first" "second"
  assert_success
  assert_output_contains "first"
}

test_first_of_second() {
  run_spell spells/.imps/out/first-of "" "second"
  assert_success
  assert_output_contains "second"
}

test_first_of_fails_both_empty() {
  run_spell spells/.imps/out/first-of "" ""
  assert_failure
}

run_test_case "first-of returns first non-empty" test_first_of_first
run_test_case "first-of returns second if first empty" test_first_of_second
run_test_case "first-of fails if both empty" test_first_of_fails_both_empty

finish_tests
