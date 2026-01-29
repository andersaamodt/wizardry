#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_create_avatar_exists() {
  [ -x "spells/.imps/mud/create-avatar" ]
}

run_test_case "create-avatar is executable" test_create_avatar_exists
finish_tests
