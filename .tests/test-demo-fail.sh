#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_fails_with_reason() {
  printf 'This is diagnostic output from the test\n' >&2
  printf 'More debugging information here\n' >&2
  TEST_FAILURE_REASON="expected foo=5 but got foo=3"
  export TEST_FAILURE_REASON
  return 1
}

run_test_case "test with detailed failure" test_fails_with_reason

finish_tests
