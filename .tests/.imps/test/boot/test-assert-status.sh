#!/bin/sh
# Test assert-status imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_status_matches() {
  assert_status 0 0
}

test_status_mismatch() {
  if assert_status 0 1; then
    return 1
  fi
  return 0
}

test_status_nonzero_match() {
  assert_status 127 127
}

run_test_case "assert-status matches expected status" test_status_matches
run_test_case "assert-status fails on mismatch" test_status_mismatch
run_test_case "assert-status matches non-zero status" test_status_nonzero_match

finish_tests
