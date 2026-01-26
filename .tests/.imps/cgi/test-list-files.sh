#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_list_files_exists() {
  [ -x "spells/.imps/cgi/list-files" ]
}

run_test_case "list-files is executable" test_list_files_exists
finish_tests
