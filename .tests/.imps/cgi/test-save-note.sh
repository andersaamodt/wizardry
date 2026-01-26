#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_save_note_exists() {
  [ -x "spells/.imps/cgi/save-note" ]
}

run_test_case "save-note is executable" test_save_note_exists
finish_tests
