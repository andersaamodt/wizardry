#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_nginx_admin_help() {
  run_spell "spells/.arcana/web-wizardry/nginx-admin" --help
  assert_success && assert_output_contains "certbot"
}

run_test_case "nginx-admin shows help" test_nginx_admin_help
finish_tests
