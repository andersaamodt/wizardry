#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_echo_text_exists() {
  [ -x "spells/.imps/cgi/echo-text" ]
}

run_test_case "echo-text is executable" test_echo_text_exists
finish_tests
