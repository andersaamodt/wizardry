#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_is_web_component_installed_help() {
  run_spell "spells/.arcana/web-wizardry/is-web-component-installed" --help
  assert_success && assert_output_contains "certbot"
}

run_test_case "is-web-component-installed shows help" test_is_web_component_installed_help
finish_tests
