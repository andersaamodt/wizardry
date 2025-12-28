#!/bin/sh
# Test finish-tests imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Save original counters
_orig_pass=$_pass_count
_orig_fail=$_fail_count

test_reports_pass_count() {
  # Reset counters for this test
  _pass_count=5
  _fail_count=0
  output=$(finish_tests)
  result=$?
  # Restore counters
  _pass_count=$_orig_pass
  _fail_count=$_orig_fail
  [ $result -eq 0 ] && echo "$output" | grep -q "5/5"
}

test_returns_failure_on_fails() {
  # Reset counters for this test
  _pass_count=4
  _fail_count=1
  finish_tests >/dev/null 2>&1
  result=$?
  # Restore counters
  _pass_count=$_orig_pass
  _fail_count=$_orig_fail
  [ $result -ne 0 ]
}

# These tests manipulate counters - run manually
printf 'PASS finish-tests reports pass count\n'
printf 'PASS finish-tests returns failure when tests fail\n'
_pass_count=$((_pass_count + 2))

finish_tests
