#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_install_htmx_help() {
  run_spell "spells/.arcana/web-wizardry/install-htmx" --help
  assert_success && assert_output_contains "htmx"
}

run_test_case "install-htmx shows help" test_install_htmx_help
finish_tests
