#!/bin/sh
# Test assert-status imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_status_matches() {
  STATUS=0
  _assert_status 0
}

test_status_mismatch() {
  STATUS=1
  if _assert_status 0; then
    return 1
  fi
  return 0
}

test_status_nonzero_match() {
  STATUS=127
  _assert_status 127
}

_run_test_case "assert-status matches expected status" test_status_matches
_run_test_case "assert-status fails on mismatch" test_status_mismatch
_run_test_case "assert-status matches non-zero status" test_status_nonzero_match

_finish_tests
