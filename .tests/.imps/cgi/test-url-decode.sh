#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_url_decode_exists() {
  [ -x "spells/.imps/cgi/url-decode" ]
}

run_test_case "url-decode is executable" test_url_decode_exists
finish_tests
