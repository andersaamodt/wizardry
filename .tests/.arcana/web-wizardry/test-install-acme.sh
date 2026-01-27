#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_install_acme_help() {
  _run_spell "spells/.arcana/web-wizardry/install-acme" --help
  assert_success && assert_output_contains "certbot"
}

_run_test_case "install-acme shows help" test_install_acme_help
finish_tests
