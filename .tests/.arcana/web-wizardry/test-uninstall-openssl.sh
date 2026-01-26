#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_uninstall_openssl_help() {
  run_spell "spells/.arcana/web-wizardry/uninstall-openssl" --help
  assert_success && assert_output_contains "certbot"
}

run_test_case "uninstall-openssl shows help" test_uninstall_openssl_help
finish_tests
