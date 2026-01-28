#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_drag_drop_upload_exists() {
  [ -x "spells/.imps/cgi/drag-drop-upload" ]
}

run_test_case "drag-drop-upload is executable" test_drag_drop_upload_exists
finish_tests
