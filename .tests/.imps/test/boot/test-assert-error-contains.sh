#!/bin/sh
# Test assert-error-contains imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_matches_substring() {
  ERROR="some error message here"
  assert_error_contains "error message"
}

test_no_match() {
  ERROR="some error message here"
  if assert_error_contains "not found"; then
    return 1
  fi
  return 0
}

run_test_case "assert-error-contains matches substring" test_matches_substring
run_test_case "assert-error-contains fails when substring missing" test_no_match

finish_tests
