#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_uninstall_origin_bridge_runtime_help() {
  run_spell "spells/.arcana/crossposting/uninstall-origin-bridge-runtime" --help
  assert_success && assert_output_contains "managed origin-bridge"
}

run_test_case "uninstall-origin-bridge-runtime shows help" test_uninstall_origin_bridge_runtime_help
finish_tests
