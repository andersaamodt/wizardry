#!/bin/sh
# Test http-end-headers imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_http_end_headers_works() {
  run_spell spells/.imps/cgi/http-end-headers
  assert_success
}

run_test_case "http-end-headers works" test_http_end_headers_works

finish_tests
