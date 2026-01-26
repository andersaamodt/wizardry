#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_temperature_convert_exists() {
  [ -x "spells/.imps/cgi/temperature-convert" ]
}

run_test_case "temperature-convert is executable" test_temperature_convert_exists
finish_tests
