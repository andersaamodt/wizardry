#!/bin/sh
# Test site-menu spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_site_menu_help() {
  run_spell spells/web/site-menu --help
  assert_success
  assert_output_contains "Usage:"
}

run_test_case "site-menu --help" test_site_menu_help

finish_tests
