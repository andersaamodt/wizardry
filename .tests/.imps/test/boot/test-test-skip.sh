#!/bin/sh
# Test test-skip imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_outputs_skip_with_reason() {
  output=$(test-skip 1 "test description" "mode mismatch")
  echo "$output" | grep -q "^SKIP #1 test description: mode mismatch$"
}

test_outputs_skip_without_reason() {
  output=$(test-skip 2 "test description" "")
  echo "$output" | grep -q "^SKIP #2 test description$"
}

test_includes_test_number() {
  output=$(test-skip 3 "test desc" "reason")
  echo "$output" | grep -q "^SKIP #3"
}

run_test_case "test-skip outputs SKIP with reason" test_outputs_skip_with_reason
run_test_case "test-skip outputs SKIP without reason" test_outputs_skip_without_reason
run_test_case "test-skip includes test number" test_includes_test_number

finish_tests
