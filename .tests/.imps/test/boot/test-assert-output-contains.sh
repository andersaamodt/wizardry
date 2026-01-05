#!/bin/sh
# Test assert-output-contains imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_matches_substring() {
  assert_output_contains "output text" "some output text here"
}

test_no_match() {
  if assert_output_contains "not found" "some output text here"; then
    return 1
  fi
  return 0
}

run_test_case "assert-output-contains matches substring" test_matches_substring
run_test_case "assert-output-contains fails when substring missing" test_no_match

finish_tests
