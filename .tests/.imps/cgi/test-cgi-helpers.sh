#!/bin/sh
# Basic tests for CGI helper imps

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_http_status_works() {
  run_spell spells/.imps/cgi/http-status 200 "OK"
  assert_success
  assert_output_contains "200 OK"
}

test_http_header_works() {
  run_spell spells/.imps/cgi/http-header "Content-Type" "text/html"
  assert_success
  assert_output_contains "Content-Type: text/html"
}

test_http_end_headers_works() {
  run_spell spells/.imps/cgi/http-end-headers
  assert_success
}

test_url_decode_works() {
  run_spell spells/.imps/cgi/url-decode "hello%20world"
  assert_success
  assert_output_contains "hello world"
}

run_test_case "http-status works" test_http_status_works
run_test_case "http-header works" test_http_header_works
run_test_case "http-end-headers works" test_http_end_headers_works
run_test_case "url-decode works" test_url_decode_works

finish_tests
