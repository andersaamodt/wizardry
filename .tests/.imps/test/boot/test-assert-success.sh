#!/bin/sh
# Test assert-success imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_zero_status() {
  assert_success 0
}

test_nonzero_status_fails() {
  if assert_success 1; then
    return 1
  fi
  return 0
}

run_test_case "assert-success succeeds on zero status" test_zero_status
run_test_case "assert-success fails on non-zero status" test_nonzero_status_fails

finish_tests
