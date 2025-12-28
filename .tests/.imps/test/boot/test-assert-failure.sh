#!/bin/sh
# Test assert-failure imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_nonzero_status() {
  STATUS=1
  assert_failure
}

test_zero_status_fails() {
  STATUS=0
  if assert_failure; then
    return 1
  fi
  return 0
}

run_test_case "assert-failure succeeds on non-zero status" test_nonzero_status
run_test_case "assert-failure fails on zero status" test_zero_status_fails

finish_tests
