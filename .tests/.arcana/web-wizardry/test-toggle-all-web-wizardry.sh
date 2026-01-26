#!/bin/sh
test_root=$(CDPATH= cd -- "$(dirname "$0")" && pwd -P)
while [ ! -f "$test_root/spells/.imps/test/test-bootstrap" ] && [ "$test_root" != "/" ]; do
  test_root=$(dirname "$test_root")
done
. "$test_root/spells/.imps/test/test-bootstrap"

test_toggle_all_web_wizardry_help() {
  run_spell "spells/.arcana/web-wizardry/toggle-all-web-wizardry" --help
  assert_success && assert_output_contains "certbot"
}

run_test_case "toggle-all-web-wizardry shows help" test_toggle_all_web_wizardry_help
finish_tests
