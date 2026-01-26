#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_upload_image_exists() {
  [ -x "spells/.imps/cgi/upload-image" ]
}

run_test_case "upload-image is executable" test_upload_image_exists
finish_tests
