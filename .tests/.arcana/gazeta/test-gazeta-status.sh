#!/bin/sh

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_gazeta_status_help() {
  run_spell "spells/.arcana/gazeta/gazeta-status" --help
  assert_success || return 1
  assert_output_contains "Usage: gazeta-status"
}

test_gazeta_status_reports_not_installed() {
  skip-if-compiled || return $?

  tmp=$(make_tempdir)
  run_cmd env GAZETA_DIR="$tmp/missing" \
    "$ROOT_DIR/spells/.arcana/gazeta/gazeta-status"
  assert_success || return 1
  assert_output_contains "not installed"
}

run_test_case "gazeta-status shows help" test_gazeta_status_help
run_test_case "gazeta-status reports not installed" \
  test_gazeta_status_reports_not_installed
finish_tests
