#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
# shellcheck source=/dev/null
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  run_spell "spells/.arcana/mud/toggle-avatar" --help
  assert_success && assert_output_contains "Usage: toggle-avatar"
}

run_test_case "toggle-avatar prints usage" test_help

finish_tests
