#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_log_timestamp_exists() {
  [ -x "spells/.imps/out/log-timestamp" ]
}

run_test_case "log-timestamp is executable" test_log_timestamp_exists
finish_tests
