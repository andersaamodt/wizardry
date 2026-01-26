#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_example_cgi_exists() {
  [ -x "spells/.imps/cgi/example-cgi" ]
}

run_test_case "example-cgi is executable" test_example_cgi_exists
finish_tests
