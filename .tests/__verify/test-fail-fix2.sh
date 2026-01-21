#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pass() { return 0; }
test_fail_with_reason() { TEST_FAILURE_REASON="expected foo, got bar"; return 1; }
test_fail_no_reason() { return 1; }

run_test_case "pass test" test_pass
run_test_case "fail with custom reason" test_fail_with_reason
run_test_case "fail with default reason" test_fail_no_reason
finish_tests
