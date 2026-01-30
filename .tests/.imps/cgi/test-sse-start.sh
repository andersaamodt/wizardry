#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_sse_start_exists() {
  [ -x "spells/.imps/cgi/sse-start" ]
}

run_test_case "sse-start is executable" test_sse_start_exists
finish_tests
