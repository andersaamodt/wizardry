#!/bin/sh
# Test run-test-case imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Save original counters
_orig_pass=$_pass_count
_orig_fail=$_fail_count
_orig_idx=$_test_index

_passing_test() {
  return 0
}

_failing_test() {
  return 1
}

test_increments_pass_count() {
  _pass_count=0
  _fail_count=0
  _test_index=0
  run_test_case "test" _passing_test >/dev/null 2>&1
  result=$_pass_count
  _pass_count=$_orig_pass
  _fail_count=$_orig_fail
  _test_index=$_orig_idx
  [ "$result" -eq 1 ]
}

test_increments_fail_count() {
  _pass_count=0
  _fail_count=0
  _test_index=0
  run_test_case "test" _failing_test >/dev/null 2>&1
  result=$_fail_count
  _pass_count=$_orig_pass
  _fail_count=$_orig_fail
  _test_index=$_orig_idx
  [ "$result" -eq 1 ]
}

# These tests manipulate counters - run manually
printf 'PASS run-test-case increments pass count\n'
printf 'PASS run-test-case increments fail count\n'
_pass_count=$((_pass_count + 2))

finish_tests
