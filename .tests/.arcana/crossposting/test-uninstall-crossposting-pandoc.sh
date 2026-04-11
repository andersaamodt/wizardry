#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_uninstall_crossposting_pandoc_help() {
  run_spell "spells/.arcana/crossposting/uninstall-crossposting-pandoc" --help
  assert_success && assert_output_contains "markdown rendering"
}

run_test_case "uninstall-crossposting-pandoc shows help" test_uninstall_crossposting_pandoc_help
finish_tests
