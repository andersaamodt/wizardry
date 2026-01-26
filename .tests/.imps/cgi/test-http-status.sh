#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_http_status_exists() {
  [ -x "spells/.imps/cgi/http-status" ]
}

run_test_case "http-status is executable" test_http_status_exists
finish_tests
