#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_install_crossposting_jq_help() {
  run_spell "spells/.arcana/crossposting/install-crossposting-jq" --help
  assert_success && assert_output_contains "Origin"
}

run_test_case "install-crossposting-jq shows help" test_install_crossposting_jq_help
finish_tests
