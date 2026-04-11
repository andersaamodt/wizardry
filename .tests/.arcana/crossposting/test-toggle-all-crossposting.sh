#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_toggle_all_crossposting_help() {
  run_spell "spells/.arcana/crossposting/toggle-all-crossposting" --help
  assert_success && assert_output_contains "Granary runtime"
}

run_test_case "toggle-all-crossposting shows help" test_toggle_all_crossposting_help
finish_tests
