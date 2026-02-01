#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_list_system_files_exists() {
  [ -x "spells/.imps/cgi/list-system-files" ]
}

run_test_case "list-system-files is executable" test_list_system_files_exists
finish_tests
