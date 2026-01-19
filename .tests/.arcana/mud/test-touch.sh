#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_touch_wrapper_exists() {
  assert_path_exists "spells/.arcana/mud/touch"
}

test_touch_can_be_sourced() {
  # Touch wrapper should be sourceable
  (
    . "$test_root/spells/.arcana/mud/touch" 2>/dev/null
    assert_success
  )
}

run_test_case "touch wrapper exists" test_touch_wrapper_exists
run_test_case "touch wrapper can be sourced" test_touch_can_be_sourced
finish_tests
