#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_http_end_headers_exists() {
  [ -x "spells/.imps/cgi/http-end-headers" ]
}

run_test_case "http-end-headers is executable" test_http_end_headers_exists
finish_tests
