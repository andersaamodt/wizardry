#!/bin/sh
# Test test-summary imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_all_passed_no_skipped() {
  output=$(test-summary 5 5 0)
  echo "$output" | grep -q "^✓ 5/5 tests passed$"
}

test_some_failed_no_skipped() {
  output=$(test-summary 3 5 0)
  echo "$output" | grep -q "^✗ 3/5 tests passed (2 failed)$"
}

test_all_passed_with_skipped() {
  output=$(test-summary 3 5 2)
  # 3 passed + 2 skipped = 5 total, 0 failed
  echo "$output" | grep -q "^✓ 3/5 tests passed (2 skipped)$"
}

test_some_failed_with_skipped() {
  output=$(test-summary 2 5 2)
  # 2 passed + 2 skipped = 4, so 1 failed
  echo "$output" | grep -q "^✗ 2/5 tests passed (1 failed, 2 skipped)$"
}

run_test_case "test-summary all passed no skipped" test_all_passed_no_skipped
run_test_case "test-summary some failed no skipped" test_some_failed_no_skipped
run_test_case "test-summary all passed with skipped" test_all_passed_with_skipped
run_test_case "test-summary some failed with skipped" test_some_failed_with_skipped

finish_tests
