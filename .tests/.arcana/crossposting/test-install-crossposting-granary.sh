#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_install_crossposting_granary_help() {
  run_spell "spells/.arcana/crossposting/install-crossposting-granary" --help
  assert_success && assert_output_contains "Granary runtime"
}

run_test_case "install-crossposting-granary shows help" test_install_crossposting_granary_help
finish_tests
