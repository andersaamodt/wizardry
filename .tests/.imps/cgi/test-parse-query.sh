#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_parse_query_exists() {
  [ -x "spells/.imps/cgi/parse-query" ]
}

run_test_case "parse-query is executable" test_parse_query_exists
finish_tests
