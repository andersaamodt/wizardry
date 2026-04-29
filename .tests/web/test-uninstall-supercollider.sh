#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

target="spells/web/uninstall-supercollider"

test_help() {
  run_spell "$target" --help
  assert_success
  assert_output_contains "Usage: uninstall-supercollider"
}

run_test_case "uninstall-supercollider shows help" test_help

finish_tests
