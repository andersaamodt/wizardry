#!/bin/sh
# Test configure-nginx spell

test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_configure_nginx_help() {
  run_spell spells/web/configure-nginx --help
  assert_success
  assert_output_contains "Usage:"
}

run_test_case "configure-nginx --help" test_configure_nginx_help

finish_tests
