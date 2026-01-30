#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_sse_event_exists() {
  [ -x "spells/.imps/cgi/sse-event" ]
}

run_test_case "sse-event is executable" test_sse_event_exists
finish_tests
