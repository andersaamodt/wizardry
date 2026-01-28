#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_debug_test_exists() {
  [ -x "spells/.imps/cgi/debug-test" ]
}

run_test_case "debug-test is executable" test_debug_test_exists
finish_tests
