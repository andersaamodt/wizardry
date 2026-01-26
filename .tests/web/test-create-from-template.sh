#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_help() {
  _run_spell "spells/web/create-from-template" --help
  _assert_success && _assert_output_contains "Usage:"
}

_run_test_case "create-from-template shows help" test_help
_finish_tests
