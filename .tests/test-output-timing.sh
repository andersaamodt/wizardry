#!/bin/sh
# Test if PASS/FAIL lines are being buffered or printed immediately

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_immediate_1() {
  sleep 0.5
  _run_cmd true
  _assert_success
}

test_immediate_2() {
  sleep 0.5
  _run_cmd true
  _assert_success
}

test_immediate_3() {
  sleep 0.5
  _run_cmd true
  _assert_success
}

test_immediate_4() {
  sleep 0.5
  _run_cmd true
  _assert_success
}

test_immediate_5() {
  sleep 0.5
  _run_cmd true
  _assert_success
}

_run_test_case "immediate output test 1" test_immediate_1
_run_test_case "immediate output test 2" test_immediate_2
_run_test_case "immediate output test 3" test_immediate_3
_run_test_case "immediate output test 4" test_immediate_4
_run_test_case "immediate output test 5" test_immediate_5

_finish_tests
