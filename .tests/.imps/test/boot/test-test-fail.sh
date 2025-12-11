#!/bin/sh
# Test test-fail imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_fail_without_reason() {
  output=$(_test_fail "test description")
  echo "$output" | grep -q "^FAIL test description$"
}

test_outputs_fail_with_reason() {
  output=$(_test_fail "test description" "expected error")
  echo "$output" | grep -q "^FAIL test description: expected error$"
}

test_handles_empty_reason() {
  output=$(_test_fail "test description" "")
  echo "$output" | grep -q "^FAIL test description$"
}

_run_test_case "test-fail outputs FAIL without reason" test_outputs_fail_without_reason
_run_test_case "test-fail outputs FAIL with reason" test_outputs_fail_with_reason
_run_test_case "test-fail handles empty reason" test_handles_empty_reason

_finish_tests
