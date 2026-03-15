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

test_site_menu_offers_rename_site() {
  if ! grep -q '"Rename site%' "$ROOT_DIR/spells/web/site-menu"; then
    fail "site-menu does not expose the Rename site action"
    return 1
  fi
}

run_test_case "site-menu --help" test_site_menu_help
run_test_case "site-menu offers Rename site" test_site_menu_offers_rename_site

finish_tests
