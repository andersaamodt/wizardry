#!/bin/sh
# Test test-skip imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_skip_with_reason() {
  # Unset global number to test standalone behavior
  unset WIZARDRY_GLOBAL_SUBTEST_NUM
  output=$(test_skip "test description" "mode mismatch")
  echo "$output" | grep -q "^  SKIP test description mode mismatch$"
}

test_outputs_skip_without_reason() {
  # Unset global number to test standalone behavior
  unset WIZARDRY_GLOBAL_SUBTEST_NUM
  output=$(test_skip "test description" "")
  echo "$output" | grep -q "^  SKIP test description$"
}

test_includes_leading_spaces() {
  # Unset global number to test standalone behavior
  unset WIZARDRY_GLOBAL_SUBTEST_NUM
  output=$(test_skip "test desc" "reason")
  echo "$output" | grep -q "^  SKIP"
}

run_test_case "test-skip outputs SKIP with reason" test_outputs_skip_with_reason
run_test_case "test-skip outputs SKIP without reason" test_outputs_skip_without_reason
run_test_case "test-skip includes leading spaces" test_includes_leading_spaces

finish_tests
