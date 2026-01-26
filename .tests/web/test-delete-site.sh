#!/bin/sh
# Test delete-site spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_delete_site_help() {
  run_spell spells/web/delete-site --help
  assert_success
  assert_output_contains "Usage:"
}

run_test_case "delete-site --help" test_delete_site_help

finish_tests
