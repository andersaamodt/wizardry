#!/bin/sh
# Test assert-success imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_zero_status() {
  STATUS=0
  _assert_success
}

test_nonzero_status_fails() {
  STATUS=1
  if _assert_success; then
    return 1
  fi
  return 0
}

_run_test_case "assert-success succeeds on zero status" test_zero_status
_run_test_case "assert-success fails on non-zero status" test_nonzero_status_fails

_finish_tests
