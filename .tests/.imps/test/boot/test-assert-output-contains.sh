#!/bin/sh
# Test assert-output-contains imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_matches_substring() {
  OUTPUT="some output text here"
  _assert_output_contains "output text"
}

test_no_match() {
  OUTPUT="some output text here"
  if _assert_output_contains "not found"; then
    return 1
  fi
  return 0
}

_run_test_case "assert-output-contains matches substring" test_matches_substring
_run_test_case "assert-output-contains fails when substring missing" test_no_match

_finish_tests
