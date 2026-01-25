#!/bin/sh
# Tests for the 'http-status' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_http_status_200() {
  run_spell spells/.imps/cgi/http-status 200 "OK"
  assert_success
  assert_output_contains "Status: 200 OK"
}

test_http_status_404() {
  run_spell spells/.imps/cgi/http-status 404 "Not Found"
  assert_success
  assert_output_contains "Status: 404 Not Found"
}

run_test_case "http-status 200 OK" test_http_status_200
run_test_case "http-status 404 Not Found" test_http_status_404

finish_tests
