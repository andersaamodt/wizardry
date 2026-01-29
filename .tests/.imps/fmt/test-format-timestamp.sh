#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_format_timestamp_exists() {
  [ -x "spells/.imps/fmt/format-timestamp" ]
}

run_test_case "format-timestamp is executable" test_format_timestamp_exists
finish_tests
