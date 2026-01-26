#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_random_quote_exists() {
  [ -x "spells/.imps/cgi/random-quote" ]
}

run_test_case "random-quote is executable" test_random_quote_exists
finish_tests
