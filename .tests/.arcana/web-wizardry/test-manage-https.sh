#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_manage_https_help() {
  _run_spell "spells/.arcana/web-wizardry/manage-https" --help
  _assert_success && _assert_output_contains "manage-https"
}

_run_test_case "manage-https shows help" test_manage_https_help
_finish_tests
