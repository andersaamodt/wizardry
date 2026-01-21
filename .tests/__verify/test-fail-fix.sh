#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_pass() { return 0; }
test_fail_with_reason() { TEST_FAILURE_REASON="expected foo, got bar"; return 1; }
test_fail_without_reason() { return 1; }

run_test_case "should pass" test_pass
run_test_case "should fail with reason" test_fail_with_reason
run_test_case "should fail without reason" test_fail_without_reason
finish_tests
