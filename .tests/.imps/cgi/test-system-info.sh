#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_system_info_exists() {
  [ -x "spells/.imps/cgi/system-info" ]
}

run_test_case "system-info is executable" test_system_info_exists
finish_tests
