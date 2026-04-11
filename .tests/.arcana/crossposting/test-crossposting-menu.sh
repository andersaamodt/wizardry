#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_crossposting_menu_help() {
  run_spell "spells/.arcana/crossposting/crossposting-menu" --help
  assert_success && assert_output_contains "Origin bridge runtime"
}

run_test_case "crossposting-menu shows help" test_crossposting_menu_help
finish_tests
