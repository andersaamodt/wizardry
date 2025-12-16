#!/bin/sh
# Test test-skip imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_skip_with_reason() {
  output=$(_test_skip "test description" "mode mismatch")
  echo "$output" | grep -q "^  SKIP test description mode mismatch$"
}

test_outputs_skip_without_reason() {
  output=$(_test_skip "test description" "")
  echo "$output" | grep -q "^  SKIP test description$"
}

test_includes_leading_spaces() {
  output=$(_test_skip "test desc" "reason")
  echo "$output" | grep -q "^  SKIP"
}

_run_test_case "test-skip outputs SKIP with reason" test_outputs_skip_with_reason
_run_test_case "test-skip outputs SKIP without reason" test_outputs_skip_without_reason
_run_test_case "test-skip includes leading spaces" test_includes_leading_spaces

_finish_tests
