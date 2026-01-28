#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_counter_reset_exists() {
  [ -x "spells/.imps/cgi/counter-reset" ]
}

run_test_case "counter-reset is executable" test_counter_reset_exists
finish_tests
