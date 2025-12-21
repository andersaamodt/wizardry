#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pass_case() {
  return 0
}

test_fail_case() {
  TEST_FAILURE_REASON="This test failed intentionally"
  return 1
}

test_another_fail() {
  TEST_FAILURE_REASON="Another failure"
  return 1
}

_run_test_case "test that passes" test_pass_case
_run_test_case "test that fails" test_fail_case
_run_test_case "another failure" test_another_fail
_finish_tests
