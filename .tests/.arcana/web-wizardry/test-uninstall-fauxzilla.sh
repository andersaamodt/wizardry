#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_uninstall_fauxzilla_help() {
  run_spell "spells/.arcana/web-wizardry/uninstall-fauxzilla" --help
  assert_success && assert_output_contains "Fauxzilla"
}

run_test_case "uninstall-fauxzilla shows help" test_uninstall_fauxzilla_help
finish_tests
