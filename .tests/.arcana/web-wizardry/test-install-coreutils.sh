#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_install_coreutils_help() {
  run_spell "spells/.arcana/web-wizardry/install-coreutils" --help
  assert_success && assert_output_contains "certbot"
}

run_test_case "install-coreutils shows help" test_install_coreutils_help
finish_tests
