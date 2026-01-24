#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_listend_imp_exists() {
  [ -f "$test_root/spells/.imps/mud/listend" ] || fail "listend imp file does not exist"
  [ -x "$test_root/spells/.imps/mud/listend" ] || fail "listend imp is not executable"
}

run_test_case "listend imp exists and is executable" test_listend_imp_exists
finish_tests
