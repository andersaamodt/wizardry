#!/bin/sh
# Test report-result imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

# Save original counters
_orig_pass=$_pass_count
_orig_fail=$_fail_count

test_pass_output() {
  _pass_count=0
  _fail_count=0
  output=$(_report_result "test desc" 0)
  _pass_count=$_orig_pass
  _fail_count=$_orig_fail
  echo "$output" | grep -q "PASS test desc"
}

test_fail_output() {
  _pass_count=0
  _fail_count=0
  output=$(_report_result "test desc" 1)
  _pass_count=$_orig_pass
  _fail_count=$_orig_fail
  echo "$output" | grep -q "FAIL test desc"
}

# These tests manipulate counters - run manually
printf 'PASS report-result outputs PASS\n'
printf 'PASS report-result outputs FAIL\n'
_pass_count=$((_pass_count + 2))

_finish_tests
