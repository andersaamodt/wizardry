#!/bin/sh
# Test url-decode imp

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_url_decode_works() {
  run_spell spells/.imps/cgi/url-decode "hello%20world"
  assert_success
  assert_output_contains "hello world"
}

run_test_case "url-decode works" test_url_decode_works

finish_tests
