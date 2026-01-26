#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_color_picker_exists() {
  [ -x "spells/.imps/cgi/color-picker" ]
}

run_test_case "color-picker is executable" test_color_picker_exists
finish_tests
