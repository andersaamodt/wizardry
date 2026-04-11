#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_crossposting_status_help() {
  run_spell "spells/.arcana/crossposting/crossposting-status" --help
  assert_success && assert_output_contains "granary-runtime"
}

run_test_case "crossposting-status shows help" test_crossposting_status_help
finish_tests
