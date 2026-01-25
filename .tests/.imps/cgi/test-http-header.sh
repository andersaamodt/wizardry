#!/bin/sh
# Tests for the 'http-header' imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_http_header_basic() {
  run_spell spells/.imps/cgi/http-header "Content-Type" "text/html"
  assert_success
  assert_output_contains "Content-Type: text/html"
}

test_http_header_with_value() {
  run_spell spells/.imps/cgi/http-header "X-Custom-Header" "value123"
  assert_success
  assert_output_contains "X-Custom-Header: value123"
}

run_test_case "http-header basic test" test_http_header_basic
run_test_case "http-header with custom value" test_http_header_with_value

finish_tests
